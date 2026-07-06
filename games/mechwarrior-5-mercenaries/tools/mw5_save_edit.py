#!/usr/bin/env python3
"""Headless editor for MechWarrior 5: Mercenaries campaign saves on macOS.

Drives the `libmw5save` serialization library recovered from wmtorode/MW5-SaveEditor
(rebuild it locally per ../docs/SAVE-EDITING.md; it is NOT committed here). Run under the
same Python 3.9 venv you built the library in, with PYTHONPATH pointing at it:

    PYTHONPATH=/tmp/mw5edit /tmp/mw5edit/venv/bin/python mw5_save_edit.py \
        --save ".../SaveGames/<guid>/<LastSaveFileName>.sav" \
        --cbills 50000000 \
        --mech TBR-PRIME_MDA --mech TBR-PRIME_MDA \
        --weapon C-ERPPC:4 --weapon C-ERLargeLaser:6 --weapon GaussRifle_Lvl5:2 \
        --equip Clan_GaussRifle_AmmoEquipment:10 --equip ClanDoubleHeatSink:30

ALWAYS back up the SaveGames folder first, and QUIT MW5 before editing (it overwrites
external changes on its next autosave). See ../docs/SAVE-EDITING.md for the full workflow,
tier/Clan naming rules, and DLC gating.
"""
import argparse
import logging
import os
import sys

try:
    from libmw5save import Mw5Save
except ImportError:
    sys.exit(
        "libmw5save not importable. Rebuild it (see ../docs/SAVE-EDITING.md) and set\n"
        "PYTHONPATH to its parent dir. Requires the two mw5save.py decompiler-artifact fixes."
    )

log = logging.getLogger("mw5edit")

# MwAssetType is stored WITHOUT quotes. Ammo/heatsinks are equipment, everything else weapons.
# These cover the common cases; for anything exotic, look it up in libui/data/default*.py.
WEAPON_ASSET = {
    "MWProjectileWeaponDataAsset": ("Autocannon", "Gauss", "PPC", "Rifle", "LBX", "UltraAutocannon", "MachineGun"),
    "MWTraceWeaponDataAsset": ("Laser", "Flamer", "TAG"),
    "MWMissileWeaponDataAsset": ("LRM", "SRM", "Streak", "ATM", "Narc", "ATM"),
}


def guess_weapon_asset(weapon_id: str) -> str:
    """Best-effort MwAssetType from a WeaponId. Override with ID@AssetType if wrong."""
    base = weapon_id.split("_Lvl")[0].lstrip("C-")
    for asset, needles in WEAPON_ASSET.items():
        if any(n.lower() in base.lower() for n in needles):
            return asset
    return "MWTraceWeaponDataAsset"


def open_save(path: str) -> Mw5Save:
    s = Mw5Save(logger=log)
    s.loadSave(path)
    # loadSave (post-fix) parses every model; be defensive in case an unpatched copy is used.
    for item in s.models:
        if item.name == "InventoryModel" and not s.inventoryModel.inventoryArray:
            s.inventoryModel.fromBytes(item.data.value)
    return s


def add_cbills(s: Mw5Save, amount: int) -> None:
    s.inventoryModel.CBills += amount


def add_weapons(s: Mw5Save, specs) -> None:
    im = s.inventoryModel
    for wid, qty, asset in specs:
        im.inventoryArray.append(im.generateNewWeapon(wid, qty, asset))


def add_equipment(s: Mw5Save, specs) -> None:
    im = s.inventoryModel
    for eid, qty, asset in specs:
        im.inventoryArray.append(im.generateNewEquipment(eid, qty, asset))


def add_cold_storage_mechs(s: Mw5Save, mech_ids) -> None:
    im = s.inventoryModel
    if mech_ids and not im.canAddMech:
        im.addMechArray()  # save has no StoredMechInventory yet; splice one in
    for mid in mech_ids:
        im.coldStorageMechs.append(im.generateNewColdStoredMech(mid))


def save_and_verify(s: Mw5Save, path: str) -> None:
    s.writeSave(path)
    # Reload from disk and re-serialize: confirms the write parses and is stable.
    check = open_save(path)
    disk = open(path, "rb").read()
    tmp = path + ".verify.tmp"
    check.writeSave(tmp)
    stable = open(tmp, "rb").read() == disk
    os.remove(tmp)
    im = check.inventoryModel
    print(f"  C-bills: {im.CBills:,}")
    print(f"  cold-storage mechs: {[m.WeaponId for m in im.coldStorageMechs]}")
    print(f"  warehouse items: {len(im.inventoryArray)}")
    print(f"  re-serialize stable: {stable}")
    if not stable:
        sys.exit("!! written file did not re-serialize identically — DO NOT load it; restore backup")


def parse_spec(s: str):
    """'ID', 'ID:QTY', 'ID@AssetType', or 'ID:QTY@AssetType' (qty defaults to 1)."""
    asset = None
    if "@" in s:
        s, asset = s.rsplit("@", 1)
    if ":" in s:
        s, qty = s.split(":", 1)
    else:
        qty = "1"
    return s, int(qty), asset


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--save", required=True, help="path to the .sav to edit (back it up first!)")
    ap.add_argument("--cbills", type=int, default=0, help="C-bills to ADD (not set)")
    ap.add_argument("--weapon", action="append", default=[], metavar="ID[:QTY][@ASSET]",
                    help="weapon to add, repeatable; e.g. C-ERPPC:4 or GaussRifle_Lvl5:2")
    ap.add_argument("--equip", action="append", default=[], metavar="ID[:QTY][@ASSET]",
                    help="equipment/ammo/heatsink to add, repeatable")
    ap.add_argument("--mech", action="append", default=[], metavar="MDA_ID",
                    help="cold-storage mech chassis to add, repeatable; e.g. TBR-PRIME_MDA")
    args = ap.parse_args(argv)

    logging.basicConfig(level=logging.ERROR)

    weapons = [(wid, qty, asset or guess_weapon_asset(wid)) for wid, qty, asset in map(parse_spec, args.weapon)]
    equip = [(eid, qty, asset or "MWAmmoDataAsset") for eid, qty, asset in map(parse_spec, args.equip)]

    s = open_save(args.save)
    im = s.inventoryModel
    print(f"BEFORE: C-bills={im.CBills:,}  coldMechs={len(im.coldStorageMechs)}  items={len(im.inventoryArray)}")

    if args.cbills:
        add_cbills(s, args.cbills)
    add_weapons(s, weapons)
    add_equipment(s, equip)
    add_cold_storage_mechs(s, args.mech)

    print("AFTER (writing + verifying):")
    save_and_verify(s, args.save)
    print(f"OK: {args.save}")


if __name__ == "__main__":
    main()
