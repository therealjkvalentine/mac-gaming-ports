# MechWarrior 2 (1995) — research notes, no build yet

Status: **not started** — this folder holds the reference trail for a future
port/build, in the same spirit as the I76 and MW4/MW5 entries. Nothing here is
verified in play yet.

## The anchor resource: Local Ditch Gaming

[Local Ditch's MechWarrior 2 hub](https://www.localditch.com/mechwarrior/mech2/index.html)
is the same site whose I76 FAQ grounded our frame-cap work
(see [interstate-76/docs/FINDINGS-2026-07-WINDOWS-AND-TEXTURES.md](../interstate-76/docs/FINDINGS-2026-07-WINDOWS-AND-TEXTURES.md) §6).
Their MW2 coverage:

- **Installation guide** for modern systems, including **3DFX conversion
  instructions** — directly relevant to us: the 3dfx/Glide route is the same
  dgVoodoo2 territory we've already mapped for I76 (Voodoo-era wrapper on
  Windows; dgVoodoo→DXVK under Wine on the Mac).
- Covers the whole series: **31st Century Combat** (original '95), **Ghost
  Bear's Legacy**, **MW2: Mercenaries** — plus mission guides/walkthroughs,
  mech specs, cheat codes, lore/timeline, and **PDF manuals** (MW2 + GBL).
- Series history context (the protected-mode conversion saga that delayed the
  original release).

## Follow-ups for when this build starts

1. **Pick the target version first.** MW2 shipped in very different builds:
   DOS (original), Win95 "Pentium Edition", and the 3dfx **Titanium** editions.
   The DOS builds want DOSBox-staging (easy, cross-platform, works on the Mac
   too); the Win95/Titanium builds are the dgVoodoo2 candidates on the Windows
   box — our I76 recipe (Glide wrapper + conf) should transfer nearly verbatim.
2. **No GOG/Steam release exists** (BattleTech licensing) — this is a
   bring-your-own-disc title like the I76 CD path; game-data stays out of the
   repo per house rules.
3. **Check the AiO-patch-style community landscape** before building: the MW2
   community (Sarna, r/mechwarrior, VOGONS) maintains modern installers
   (e.g. "MW2 one-click" projects) — survey before hand-rolling, the way the
   I76 findings doc did for texture packs.
4. **Grab the manuals** from Local Ditch while the site is alive; their I76
   downloads page already preserves files the rest of the web lost.
5. Cross-reference the MW4 diagnosis ([mechwarrior-4-mercenaries/](../mechwarrior-4-mercenaries/README.md)):
   MW2-era protection is simpler (no SafeDisc-LDT wall expected), so the Apple
   Silicon story should be far friendlier than MW4's dead end.
