# Puts OptiScaler_DLSSNR and your DLSS 5 model into this dlss5 folder and sets OptiScaler.ini up
# for TF3-DLSS5. Nothing outside this folder is changed.
#
#   .\install-dlss5.ps1 -OptiScalerZip <zip or folder of an OptiScaler_DLSSNR release> -Model <nvngx_dlssnr.dll>
#
# Both are optional: run it again later with the one you were missing. Without arguments it only
# checks what is here and fixes OptiScaler.ini.
param(
    [string]$OptiScalerZip,
    [string]$Model
)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot

function Find-One($root, $name) {
    $f = Get-ChildItem -Path $root -Recurse -File -Filter $name -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $f) { throw "$name not found in $root" }
    return $f.FullName
}

if ($OptiScalerZip) {
    $src = $OptiScalerZip
    $tmp = $null
    if ((Test-Path $src -PathType Leaf) -and $src -match '\.zip$') {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ("tf3dlss5_" + [guid]::NewGuid())
        Expand-Archive -Path $src -DestinationPath $tmp
        $src = $tmp
    }
    if (-not (Test-Path $src -PathType Container)) { throw "-OptiScalerZip: $OptiScalerZip is neither a .zip nor a folder" }
    try {
        Copy-Item (Find-One $src 'OptiScaler.dll') $here -Force
        Copy-Item (Find-One $src 'nvngx.dll_dlssnr.dll') $here -Force
        $ini = Get-ChildItem -Path $src -Recurse -File -Filter 'OptiScaler.ini' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($ini -and -not (Test-Path (Join-Path $here 'OptiScaler.ini'))) { Copy-Item $ini.FullName $here }
        Write-Host 'OptiScaler_DLSSNR copied.' -ForegroundColor Green
    } finally {
        if ($tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ($Model) {
    if (-not (Test-Path $Model -PathType Leaf)) { throw "-Model: $Model not found" }
    Copy-Item $Model (Join-Path $here 'nvngx_dlssnr.dll') -Force
    $sig = Get-AuthenticodeSignature (Join-Path $here 'nvngx_dlssnr.dll')
    $ver = (Get-Item (Join-Path $here 'nvngx_dlssnr.dll')).VersionInfo.FileVersion
    if ($sig.Status -eq 'Valid') {
        Write-Host "Model $ver copied: NVIDIA's official signed file (for now the neural pass runs on RTX 50 cards only)." -ForegroundColor Green
    } else {
        Remove-Item (Join-Path $here 'nvngx_dlssnr.dll') -Force
        throw "Model $ver is not NVIDIA's signed file, so it was not copied. TF3-DLSS5 only supports NVIDIA's official, unmodified DLSS 5 model."
    }
}

# OptiScaler.ini: set the keys TF3-DLSS5 relies on, keep everything else.
$want = [ordered]@{
    'Upscalers' = [ordered]@{ 'VulkanUpscaler' = 'dlss' }
    'DLSS'      = [ordered]@{ 'Enabled' = 'true' }
    'Inputs'    = [ordered]@{ 'EnableDlssInputs' = 'true' }
    'DlssNr'    = [ordered]@{ 'Enabled' = 'true'; 'ToggleKey' = '0x87' }
    'FrameGen'  = [ordered]@{ 'Enabled' = 'false' }
    'Menu'      = [ordered]@{ 'OverlayMenu' = 'true' }
    'Log'       = [ordered]@{ 'LogToFile' = 'true' }
}
$iniPath = Join-Path $here 'OptiScaler.ini'
$lines = New-Object System.Collections.Generic.List[string]
if (Test-Path $iniPath) { $lines.AddRange([string[]](Get-Content $iniPath)) }
foreach ($section in $want.Keys) {
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i].Trim() -eq "[$section]") { $start = $i; break } }
    if ($start -lt 0) {
        $lines.Add('')
        $lines.Add("[$section]")
        $start = $lines.Count - 1
    }
    $end = $lines.Count
    for ($i = $start + 1; $i -lt $lines.Count; $i++) { if ($lines[$i].Trim() -match '^\[.+\]$') { $end = $i; break } }
    foreach ($key in $want[$section].Keys) {
        $value = $want[$section][$key]
        $found = $false
        for ($i = $start + 1; $i -lt $end; $i++) {
            if ($lines[$i] -match "^\s*$([regex]::Escape($key))\s*=") { $lines[$i] = "$key=$value"; $found = $true; break }
        }
        if (-not $found) { $lines.Insert($start + 1, "$key=$value"); $end++ }
    }
}
[IO.File]::WriteAllLines($iniPath, [string[]]$lines)  # UTF-8 without a BOM, like the release's own file
Write-Host 'OptiScaler.ini set up for TF3-DLSS5.' -ForegroundColor Green

# What is still missing
$missing = @()
foreach ($f in 'OptiScaler.dll', 'nvngx.dll_dlssnr.dll', 'nvngx_dlssnr.dll') {
    if (-not (Test-Path (Join-Path $here $f))) { $missing += $f }
}
if ($missing.Count) {
    Write-Host ("Still missing here: " + ($missing -join ', ') + ". See README.txt.") -ForegroundColor Yellow
} else {
    Write-Host 'All set. Start the game; DLSS5-STATUS.txt in this folder will say how it went.' -ForegroundColor Green
}
