# Editing MW5 save files on macOS (headless, no Windows exe)

Goal: add mechs, weapons, equipment, ammo, or C-bills to a campaign save **without**
running a Windows save-editor GUI under Wine. MW5 saves are plain, uncompressed Unreal
Engine 4 property serialization, so they edit cleanly with a small Python driver.

The one good community editor — [wmtorode/MW5-SaveEditor](https://github.com/wmtorode/MW5-SaveEditor)
— ships as a release-only PyInstaller Windows `.exe` with **no public source**. Rather than
run it under Wine, we unpack it once to recover its (battle-tested) serialization library
`libmw5save`, then drive that library directly from macOS Python. This is offline, scriptable,
and — importantly — lets us prove a no-op load→save is **byte-identical** before trusting it
with a real edit.

> Legal note: `libmw5save` is decompiled from a third-party closed-source tool, so it is **not**
> committed here. Rebuild it locally with the steps below (a few minutes). Only our own driver
> ([`../tools/mw5_save_edit.py`](../tools/mw5_save_edit.py)) lives in the repo.

## Where the saves live

Inside the Sikarugir wrapper prefix:

```
~/Applications/Sikarugir/MechWarrior5.app/Contents/SharedSupport/prefix/drive_c/users/<user>/AppData/Local/MW5Mercs/Saved/SaveGames/<campaign-guid>/
```

Each campaign guid folder holds the `.sav` files plus `Campaign.json`. In `Campaign.json`,
`LastSaveFileName` is the save that **Continue** loads — that's the one to edit. The `.sav` is
raw UE4 records (no GVAS magic, no compression); `strings file.sav` shows readable property names.

## Rebuild `libmw5save` (one-time)

PyInstaller here targets Python 3.7; the extractors need ≤3.9. Use `uv` to get a 3.9 venv
(3.7 has no arm64 build, and the modern extractors won't install on 3.14):

```sh
cd /tmp && mkdir mw5edit && cd mw5edit
curl -L -o MW5SaveEditor.exe \
  https://github.com/wmtorode/MW5-SaveEditor/releases/download/v1.6.6/MW5SaveEditor.exe

uv venv --python 3.9 venv
VIRTUAL_ENV=$PWD/venv uv pip install pyinstxtractor-ng decompyle3 uncompyle6

./venv/bin/pyinstxtractor-ng MW5SaveEditor.exe          # -> MW5SaveEditor.exe_extracted/

# Decompile the serialization library (decompyle3 handles these cleanly):
mkdir -p libmw5save
for f in MW5SaveEditor.exe_extracted/PYZ-00.pyz_extracted/libmw5save/*.pyc; do
  ./venv/bin/decompyle3 -o . "$f"
done
# decompyle3 writes libmw5save/*.py next to the package path; collect them into ./libmw5save/
```

(If you also want the item-ID reference lists — `DEFAULT_WEAPONS`, `SOK_MECHS`, the cold-store
mech list — those live in `libui/data/*.pyc`. `decompyle3` chokes on them but `uncompyle6`
decompiles them to **stdout**: `./venv/bin/uncompyle6 <file>.pyc > out.py`.)

## Two decompiler artifacts to fix in `libmw5save/mw5save.py`

`decompyle3` mis-reconstructs two control-flow blocks. Both must be fixed or the writer
silently produces an empty/partial file:

1. **`loadSave`** gates all model parsing behind `if self.debugModels`. Parse every model
   unconditionally instead — flatten the `if debugModels … else …` so `InventoryModel`,
   `MercCompanyModel`, `TimelineModel`, `RosterModel`, `SaveStateModel`, and `MechStorageModel`
   are each parsed on every load.
2. **`writeSave`** places `datmodels.append(data)` and `datprime.append(data)` *inside* the
   `if self.debugOut:` block. Dedent both so they run every time; otherwise the output is empty.

After the fixes, a no-op round-trip is byte-identical (the driver asserts this).

## Use the driver

[`../tools/mw5_save_edit.py`](../tools/mw5_save_edit.py) imports `libmw5save` and exposes
`add_cbills`, `add_weapons`, `add_equipment`, and `add_cold_storage_mechs`. Point `PYTHONPATH`
at wherever you rebuilt `libmw5save`, run against Python 3.9, and **always back up first**:

```sh
# Back up the whole SaveGames folder before touching anything.
cp -R ".../MW5Mercs/Saved/SaveGames" ~/mw5-save-backup-$(date +%Y%m%d-%H%M)

PYTHONPATH=/tmp/mw5edit /tmp/mw5edit/venv/bin/python mw5_save_edit.py --help
```

**Quit MW5 completely first.** The game holds campaign state in memory and overwrites external
edits on its next autosave — check with `pgrep -fl MechWarrior-Win64-Shipping`.

## What edits, and what doesn't

- **Editable in the save:** which mechs you own, which weapons/equipment/ammo sit in your
  warehouse, weapon health state, per-part armor, and C-bills. Cold-storage mechs are added as a
  *chassis reference* (e.g. `TBR-PRIME_MDA`); the game instantiates the variant's default loadout,
  which you then refit in the mechlab. The editor does **not** copy a full custom loadout in.
- **Not in the save:** weapon *stats* (damage, heat, range) live in the game's `.pak` data, not
  the save. To change those you need a mod, not a save edit.

### Tiers and Clan weapons

Weapon tier is encoded as a `_Lvl<n>` suffix on the WeaponId (`_Lvl0`..`_Lvl5`; `_Lvl5` = max,
plain name ≈ tier 2). Clan `C-*` weapons are non-leveled (already top-tier) — use the bare name.
`MwAssetType` is stored **without** quotes (`MWTraceWeaponDataAsset`, `MWProjectileWeaponDataAsset`,
`MWMissileWeaponDataAsset`, `MWAmmoDataAsset`, `MWHeatSinkDataAsset`); the decompiled
`DEFAULT_WEAPONS` list has spurious embedded quotes — strip them.

### DLC gating

Clan mechs/weapons (Timber Wolf `TBR-*`, etc.) require the corresponding DLC to be present in the
save's `DLCTags` (in `Campaign.json`) — the game strips content it thinks you don't own. With all
DLC through Shadow of Kerensky, the full Clan roster is available.

## Verify before you trust it

The driver, after writing, reloads the file from disk, prints the new inventory/mech/C-bill
state, and re-serializes to confirm it's stable. The **real** test is loading the save in-game:
launch, Continue, check the Warehouse and Mech Bay → Cold Storage. If anything is off, restore
the backup.
