# Builds the release folder and zip from build\bin and build\proxy. The zip's contents go straight
# into the game folder, next to TransportFever3.exe:
#   dist\release\version.dll           enables the layer for the game (build\proxy)
#   dist\release\TF3-DLSS\             README.txt, tf3_dlss.cfg, licenses\, bin\ (layer + runtimes),
#                                       dlss5\ (README.txt, install-dlss5.ps1; the player adds the DLSS 5 files)
#   dist\TF3-DLSS5-<ver>.zip
# and the two mod.io uploads (each zip holds the mod folder, ready for the game's staging_area):
#   dist\TF3-DLSS5-modio-<ver>.zip            menu mod + "Windows add-on" folder (the release above
#                                              and HOW-TO-INSTALL.txt), copied by hand by the player
#   dist\TF3-DLSS5-modio-menu-only-<ver>.zip  menu mod alone, linking to the GitHub release (use it
#                                              if mod.io doesn't accept the add-on's DLLs)
# Run build.ps1 (Release) first. Upload the zip to the GitHub release; it's not kept in git.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$bin  = Join-Path $root 'build\bin'
$pkg  = Join-Path $root 'package'
$dist = Join-Path $root 'dist'
$rel  = Join-Path $dist 'release'
$out  = Join-Path $rel 'TF3-DLSS'
$proxy = Join-Path $root 'build\proxy\version.dll'

$ver = (Select-String -Path (Join-Path $root 'layer\src\layer.cpp') -Pattern '#define TF3_DLSS_VERSION "(.+)"').Matches[0].Groups[1].Value
if (-not $ver) { throw 'TF3_DLSS_VERSION not found in layer.cpp' }

$need = 'VkLayer_tf3_dlss.dll', 'VkLayer_tf3_dlss.json', 'nvngx_dlss.dll', 'amd_fidelityfx_vk.dll'
foreach ($f in $need) { if (-not (Test-Path (Join-Path $bin $f))) { throw "build\bin\$f is missing (build.ps1, get_fsr.ps1)" } }
if (-not (Test-Path $proxy)) { throw 'build\proxy\version.dll is missing (build.ps1)' }

# The shipped cfg must have the developer options off.
$cfg = Get-Content (Join-Path $root 'tf3_dlss.cfg') -Raw
foreach ($pair in 'debug_keys=0', 'debug_view=0', 'dlss_dev=0', 'fsr_debug=0', 'overlay=0', 'perf=0', 'enabled=1', 'upscaler=auto', 'dlss5=1', 'menu=1') {
    if ($cfg -notmatch "(?m)^$([regex]::Escape($pair))\s*$") { throw "tf3_dlss.cfg should have $pair for a release" }
}

if (Test-Path $rel) { Remove-Item $rel -Recurse -Force }
New-Item -ItemType Directory -Force (Join-Path $out 'bin'), (Join-Path $out 'licenses'), (Join-Path $out 'dlss5') | Out-Null
foreach ($f in $need) { Copy-Item (Join-Path $bin $f) (Join-Path $out 'bin') }
Copy-Item $proxy $rel
Copy-Item (Join-Path $pkg 'licenses\*') (Join-Path $out 'licenses')
Copy-Item (Join-Path $pkg 'README.txt') $out
Copy-Item (Join-Path $root 'tf3_dlss.cfg') $out
Copy-Item (Join-Path $pkg 'dlss5\*') (Join-Path $out 'dlss5')  # no NVIDIA or OptiScaler file: the player adds those

$zip = Join-Path $dist "TF3-DLSS5-$ver.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path (Join-Path $rel '*') -DestinationPath $zip
# mod.io: the menu mod, with and without the add-on. Nothing that isn't ours or shipped above.
$modSrc = Join-Path $root 'modio\tf3_dlss5_menu_1'
$modRev = (Get-Content (Join-Path $modSrc 'mod.json') -Raw | ConvertFrom-Json).revision
$luaRev = (Select-String -Path (Join-Path $modSrc 'content\tf3_dlss5\menu.script.lua') -Pattern 'local MOD_REVISION = (\d+)').Matches[0].Groups[1].Value
if ("$modRev" -ne "$luaRev") { throw "mod.json revision ($modRev) and MOD_REVISION in menu.script.lua ($luaRev) differ" }
$info = Get-Content (Join-Path $modSrc '_metadata\modinfo.json') -Raw
if ($info -match 'YOUR_MODIO_NAME') { Write-Warning 'modinfo.json still has YOUR_MODIO_NAME: put your mod.io name in before uploading' }
foreach ($variant in 'full', 'menu-only') {
    $stage = Join-Path $dist "modio-$variant"
    if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
    $mod = Join-Path $stage 'tf3_dlss5_menu_1'
    New-Item -ItemType Directory -Force $stage | Out-Null
    Copy-Item $modSrc $mod -Recurse
    if ($variant -eq 'full') {
        $addon = Join-Path $mod 'Windows add-on'
        New-Item -ItemType Directory -Force $addon | Out-Null
        Copy-Item (Join-Path $rel '*') $addon -Recurse
        Copy-Item (Join-Path $pkg 'modio\HOW-TO-INSTALL.txt') $addon
        $name = "TF3-DLSS5-modio-$ver.zip"
    } else {
        Copy-Item (Join-Path $pkg 'modio\modinfo-menu-only.json') (Join-Path $mod '_metadata\modinfo.json') -Force
        $name = "TF3-DLSS5-modio-menu-only-$ver.zip"
    }
    $mz = Join-Path $dist $name
    if (Test-Path $mz) { Remove-Item $mz }
    Compress-Archive -Path $mod -DestinationPath $mz
    Write-Host "Packaged $mz" -ForegroundColor Green
}

Get-ChildItem $rel -Recurse -File | ForEach-Object { '{0,10:N0}  {1}' -f $_.Length, $_.FullName.Substring($rel.Length + 1) }
Write-Host "Packaged $zip" -ForegroundColor Green
