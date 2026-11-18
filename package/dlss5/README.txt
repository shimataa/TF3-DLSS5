TF3-DLSS5: the dlss5 folder
===========================

DLSS 5 (NVIDIA's neural rendering) runs after DLSS. TF3-DLSS5 doesn't run the model itself: it hands
the game's frames to OptiScaler_DLSSNR, which does. Neither the model nor OptiScaler comes with this
mod; put these files in THIS folder (TF3-DLSS\dlss5, next to this README):

  OptiScaler.dll           from an OptiScaler_DLSSNR release:
                           https://github.com/Dagherbou/OptiScaler_DLSSNR/releases
  nvngx.dll_dlssnr.dll     from the SAME OptiScaler_DLSSNR release (the two must match)
  OptiScaler.ini           from the same release (optional; install-dlss5.ps1 makes one if missing)
  nvngx_dlssnr.dll         NVIDIA's DLSS 5 model. Not shipped with any mod; you supply your own.
                           Only NVIDIA's official, unmodified (signed) file is supported. For now it
                           runs the neural pass on RTX 50 cards only; NVIDIA has announced support
                           for more cards later. Modified builds are not supported.

The easy way: install-dlss5.ps1 (in this folder) copies them here and sets OptiScaler.ini up.
Right-click it > "Run with PowerShell", or from a PowerShell window:

  .\install-dlss5.ps1 -OptiScalerZip C:\Downloads\OptiScaler_DLSSNR.zip -Model C:\Files\nvngx_dlssnr.dll

(-OptiScalerZip also takes an unpacked folder.)

By hand: copy the files above here, then make sure OptiScaler.ini has these lines in these
sections (TF3-DLSS5 relies on them):

  [Upscalers]   VulkanUpscaler=dlss     DLSS itself runs inside OptiScaler, then DLSS 5 after it
  [DLSS]        Enabled=true
  [Inputs]      EnableDlssInputs=true   OptiScaler takes over TF3-DLSS's DLSS calls
  [DlssNr]      Enabled=true            the DLSS 5 pass
  [DlssNr]      ToggleKey=0x87          F24: the in-game menu's DLSS 5 ON/OFF presses it
  [FrameGen]    Enabled=false           TF3-DLSS doesn't use OptiScaler's frame generation
  [Menu]        OverlayMenu=true        OptiScaler's own menu (Insert): DLSS 5 strength, colour...

Then start the game. Each start writes DLSS5-STATUS.txt here: what was found, what is missing and
what to do next. The [dlss5] lines in TF3-DLSS\tf3_dlss.log and OptiScaler.log (here) say more.

Turning DLSS 5 off: dlss5=0 in TF3-DLSS\tf3_dlss.cfg (restart), or DLSS 5 OFF in the in-game menu.
Removing it: delete the files above; TF3-DLSS5 is then plain TF3-DLSS (DLSS / FSR 3.1).

Notes
- Only with DLSS (upscaler=auto or dlss on an NVIDIA RTX card). With FSR 3.1 there is no DLSS 5.
- DLSS 5 costs frame rate (around a third on an RTX 4090 in early tests), more on smaller cards.
  A lower Resolution scale in the game, or OptiScaler's WorkingScale, wins some of it back.
- The model was tuned on realistic games; on a transport map it may look different from what you
  expect. Compare with DLSS 5 OFF in the in-game menu.
- Nothing here is supported by NVIDIA, Urban Games or the OptiScaler project. If the game won't
  start with DLSS 5, set dlss5=0 and report the problem with tf3_dlss.log, OptiScaler.log and
  DLSS5-STATUS.txt.
