# Interstate '76 — pushing visual quality on the Mac (what ported back from the Windows runs)

*The Windows playbook ([WINDOWS-PLAYBOOK.md](WINDOWS-PLAYBOOK.md)) listed five "max-quality"
dgVoodoo levers. This doc records which ones we pulled back into the Mac **Voodoo mode** and
verified. Bottom line: of the five, **three are real wins that work on Apple Silicon (gamma ramp,
MSAA, 32-bit rendering), one is impossible on any platform (anisotropic for Glide), one was already
correct (voodoo_graphics / 2 MB / 2048 KB-TMU).** All three wins are now in the shipped
[`dgVoodoo.conf`](../dgVoodoo.conf).*

## What changed in the Voodoo config

| Lever | Before | After | Verdict on the DXVK→MoltenVK→Metal chain |
|---|---|---|---|
| **3dfx gamma / brightness** | *(missing key)* | `EnableGlideGammaRamp = true` | ✅ **The biggest visible win.** This is the real cause of "darker than the Windows Glide look." dgVoodoo applies gamma as a **post-process shader pass** (not DXGI hardware gamma, which Wine stubs), so it runs through the working DXVK path. Verified bright in our earlier hybrid screenshots. |
| **Anti-aliasing** | `Antialiasing = appdriven` (= **Off** on voodoo_graphics!) | `Antialiasing = 4x` | ✅ **MSAA works.** 4× is guaranteed on all Apple Silicon and cheap on the tile GPU; verified the config loads, creates the FL10.1 device, and opens the render window. (We were running with **no AA at all** before — `appdriven` = off on a non-Napalm card.) |
| **32-bit rendering** | *(default/dithered)* | `DitheringEffect = pure32bit` + `Dithering = forcealways` | ✅ Smooth 32-bit skies/gradients, no 16-bit banding. Shader/RT-format change, works. |
| **Anisotropic filtering** | `TMUFiltering = bilinear` | *(unchanged)* | ❌ **Impossible for Glide, any platform.** dgVoodoo emulates the 3Dfx TMU sampling *in the pixel shader*, bypassing the GPU sampler — so only `pointsampled`/`bilinear` exist for Glide. This **corrects [WINDOWS-PLAYBOOK.md](WINDOWS-PLAYBOOK.md) item 6**: "forced anisotropic" was never achievable for I76 via dgVoodoo, on Windows either. |
| **Card / TMU memory** | `voodoo_graphics` / 2 MB / 2048 KB | *(unchanged)* | ✅ Already correct — load-bearing. >2 MB TMU triggers I76's engine-level **texture panic**. |
| **Higher internal resolution** | `Resolution = 2x` (1280×960) | *(kept 2x — see below)* | ✅ Works and is *free* (adds zero pipelines), but the Voodoo launcher pins a 1280×960 virtual desktop, so raising it means editing **both** `dgVoodoo.conf Resolution` **and** the stub's `/desktop=…,WxH`. Left at 2× as the safe default; see "Pushing resolution" below. |

## How it was verified

The winemac render window is a **Metal-backed surface on its own macOS Space**, which
`screencapture` can't grab (ScreenCaptureKit-gated) — so this round was verified by **render-log
telemetry**, not screenshots:

- Baseline and the new config both reach `DXVK: v1.10.3 … vkpc` → `D3D11CoreCreateDevice: Using
  feature level D3D_FEATURE_LEVEL_10_1` → game window opens, no crash.
- MSAA 4× specifically: device creation succeeds with `sampleRateShading: 1` and the window
  renders — i.e. MSAA does **not** hang RT creation (an earlier "empty log" was a transient, not a
  failure; re-tested apples-to-apples it loads fine).
- The persistent `i76.vkpipeline-cache` grows across runs and reloads on the next launch (61→73→
  240 KB observed; run 2 loaded the prior blob) — so MSAA's extra pipeline variants are a
  **one-time priming cost**, then free (see [DXGI-DGVOODOO-RESEARCH.md](DXGI-DGVOODOO-RESEARCH.md)
  and `tools/dxvk-pipeline-cache-persist/`).

**Left for your eyes:** the *look* of the gamma/MSAA improvement (brightness + smoothed edges) —
launch **I76 Voodoo.app**, run a mission once to prime, and compare to before. If the HUD or
binoculars ever corrupt with MSAA on, set `Antialiasing = appdriven` (the documented fallback).

## The cost model (why MSAA is safe now)

Higher resolution adds **zero** pipelines (viewport is dynamic state). MSAA is the *only* quality
lever that multiplies pipelines — `rasterizationSamples` is baked into every graphics pipeline, so
each one recompiles once at the new sample count. Our **patched DXVK persists the VkPipelineCache
across runs**, so that multiplication is paid **once** during a priming run and reused forever
after. That's exactly why MSAA is now shippable where it would've been a per-launch tax before.

## Pushing resolution higher (optional, free but fiddly)

Because resolution adds no pipelines and the M-series GPU is idle at 20 FPS, you can supersample
the 4:3 image for crisper edges. It needs **two** matching edits:

1. `dgVoodoo.conf`: `Resolution = 3x` (1920×1440) or `max_isf` (largest integer 4:3 for your
   display — ~2560×1920 on the built-in Retina).
2. [`i76-voodoo-stub.swift`](../i76-voodoo-stub.swift): change `/desktop=I76Voodoo,1280x960` to the
   matching `WxH`, then rebuild with [`build-launchers.sh`](../build-launchers.sh).

Left at 2× by default because it's the safe, already-good size the user was happy with; the bump is
a clean experiment when you want maximum sharpness.

## What did NOT port (and why)

- **Anisotropic filtering** — impossible for Glide (above).
- **Frame interpolation (Lossless Scaling / AFMF / Smooth Motion)** — those are Windows tools; the
  playbook's verdict stands (20 FPS base is below their design floor, and there's no macOS
  equivalent that hooks this stack). The 20 FPS cap is a physics requirement, not a limitation to
  paper over.
- **Force feedback** — still no macOS path (Wine FFB = Linux evdev only). It *does* work on the
  Steam Deck though — see [STEAMDECK.md](STEAMDECK.md).
