TF3-DLSS5 (TF3-DLSS 0.1.0 + DLSS 5)  -  DLSS, FSR 3.1 and DLSS 5 for Transport Fever 3
==========================================================================================

Replaces the game's built-in upscaler (FSR 1) with NVIDIA DLSS or AMD FSR 3.1,
for a sharper, steadier image at the same render resolution, or the same
image at a lower one. On top of DLSS it can run NVIDIA's DLSS 5 neural
rendering, and it can be set from inside the game with the TF3-DLSS5 mod
from the game's mod browser (mod.io). Based on TF3-DLSS by Lucas (MIT). Unofficial mod; not made
or endorsed by Urban Games, NVIDIA, AMD or the OptiScaler project.


REQUIREMENTS
------------
- Windows 10 or 11, Transport Fever 3 (Steam), Vulkan renderer (the default).
- DLSS: an NVIDIA GeForce RTX card (20 series or newer) and a recent driver.
- FSR 3.1: any GPU that runs the game (AMD, Intel or NVIDIA).


INSTALL
-------
1. Open the game folder: in Steam, right-click Transport Fever 3, then
   Manage > Browse local files.
2. Copy everything from the zip into that folder, next to
   TransportFever3.exe: version.dll and the TF3-DLSS folder. No game files
   are replaced, and nothing is installed anywhere else.
3. Start the game as usual and pick a "Resolution scale" in the game's
   graphics options: 67% (Quality) or 50% (Performance) for more frames,
   or 100% for native-resolution anti-aliasing (DLAA, no speed-up).

version.dll is a small stand-in for the Windows file of the same name: the
game loads it from its own folder, it tells Vulkan where the mod is (for this
game only), and passes everything else on to the real version.dll.


UPDATE
------
Close the game and copy the new zip's contents over the old ones.


USING IT
--------
Settings are in tf3_dlss.cfg (open it with Notepad). Every line is explained
there. Most changes apply while the game runs, as soon as you save the file.

To compare with the game's own upscaling, set debug_keys=1 in tf3_dlss.cfg.
Then, in game:
  Ctrl+Shift+D   upscaler on / off (off = the game's own FSR 1)
  Ctrl+Shift+U   switch between DLSS and FSR 3.1 (NVIDIA RTX cards)


IN-GAME MENU (mod.io)
---------------------
Subscribe to "TF3-DLSS5" in the game's mod browser and enable it. (That mod
also carries this add-on, in its "Windows add-on" folder.) A D5
button appears at the top left of the screen, next to the Layers button. It
opens a row of settings: Upscaler ON/OFF, DLSS 5 ON/OFF, sharpness, info box.
Each change applies within a second, is kept in tf3_dlss.cfg, and shows the
info box for a few seconds as a confirmation. (The menu writes to the game
log, stdout.txt, and this mod reads it; menu=0 in tf3_dlss.cfg ignores it.)


DLSS 5
------
DLSS 5 needs files this mod can't include: OptiScaler_DLSSNR and NVIDIA's
DLSS 5 model (nvngx_dlssnr.dll). dlss5\README.txt says where they come from
and how to add them (dlss5\install-dlss5.ps1 does it for you). Without them
you simply get DLSS. Each start writes dlss5\DLSS5-STATUS.txt with what was
found and what to do next. Only NVIDIA's official, unmodified model file is
supported; for now it runs the neural pass on RTX 50 cards only (NVIDIA has
announced support for more cards later). DLSS 5 costs frame rate. Its fine settings are in OptiScaler's menu: press Insert in game.


CHOOSING AN UPSCALER
--------------------
upscaler=auto is the default: DLSS on NVIDIA RTX cards, FSR 3.1 otherwise.
To use FSR on an NVIDIA card, set upscaler=fsr in tf3_dlss.cfg.

Other useful settings:
  sharpness=0.3       DLSS sharpening, 0 (off) to 1
  fsr_sharpness=0.5   FSR sharpening, 0 (off) to 1
  preset=11       DLSS model (K); 13 (M) can look better at 50% on RTX 40/50
  mip_bias=auto   sharper textures; -2 is sharper still, but fences shimmer


IF SOMETHING IS WRONG
---------------------
- No change in game? Look for TF3-DLSS-DID-NOT-START.txt in this folder (or
  in %TEMP%). It says why the upscaler didn't run, for example DLSS isn't
  available on the GPU (set upscaler=fsr). If there is neither that file nor
  tf3_dlss.log, the mod wasn't loaded: check that version.dll and the
  TF3-DLSS folder are directly next to TransportFever3.exe.
- tf3_dlss.log in this folder (or %TEMP%) has the details. Please attach it
  to any bug report, with your GPU and the render scale you use.
- Smearing or ghosting behind moving things: people and animals currently get
  camera motion only, and smoke/clouds have no depth, so some trails there
  are expected. Anything else: please report it.
- Faint trails behind vehicles, or a slightly soft image: jitter and
  object_motion are off by default for now (possible crashes and graphics
  corruption with them on). You can turn them on in tf3_dlss.cfg.
- DLSS 5 trouble: set dlss5=0 in tf3_dlss.cfg (restart) to get plain DLSS
  back, and see dlss5\DLSS5-STATUS.txt and dlss5\OptiScaler.log.
- The in-game menu changes nothing: check the [menu] lines in tf3_dlss.log.
  If it says the game log wasn't found, set game_log= in tf3_dlss.cfg.
- To rule the mod out completely, uninstall it (or set the environment
  variable TF3_DLSS_DISABLE=1).


UNINSTALL
---------
Delete version.dll and the TF3-DLSS folder from the game folder.


CREDITS AND LICENSES
--------------------
Uses NVIDIA DLSS (NVIDIA DLSS SDK) and AMD FSR 3.1 (AMD FidelityFX SDK);
their runtimes are included unmodified. DLSS 5 runs through OptiScaler_DLSSNR
(GPL-3.0), which is not included: you add it to the dlss5 folder yourself,
like NVIDIA's DLSS 5 model, which no mod may redistribute.
TF3-DLSS's own source code is MIT licensed (licenses\TF3-DLSS-LICENSE.txt).
The NVIDIA files (bin\nvngx_dlss.dll, and the NVIDIA library inside
bin\VkLayer_tf3_dlss.dll) are not: they may only be used with this mod, not
redistributed on their own, modified or reverse engineered. Full terms in
licenses\THIRD-PARTY.txt.
NVIDIA, RTX and DLSS are trademarks of NVIDIA Corporation. AMD, FidelityFX and
FSR are trademarks of Advanced Micro Devices, Inc.
