$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$out = Join-Path $root "dist\windows"
$src = Join-Path $root "Windows\CodexTrafficLightWin.cs"
$logo = Join-Path $root "logo.png"
$icon = Join-Path $root "Windows\app.ico"
$windowsDir = if ($env:WINDIR) { $env:WINDIR } else { "C:\Windows" }
$csc = Join-Path $windowsDir "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) { throw "C# compiler not found: $csc" }

function New-IcoFromPng($sourcePath, $destPath) {
  Add-Type -AssemblyName System.Drawing
  $sizes = @(16, 24, 32, 48, 64, 128, 256)
  $source = [System.Drawing.Image]::FromFile($sourcePath)
  $images = @()
  try {
    foreach ($size in $sizes) {
      $bitmap = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
      $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
      try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $radius = [Math]::Max(3, [int][Math]::Round($size * 0.22))
        $diameter = $radius * 2
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        try {
          $path.AddArc(0, 0, $diameter, $diameter, 180, 90)
          $path.AddArc($size - $diameter - 1, 0, $diameter, $diameter, 270, 90)
          $path.AddArc($size - $diameter - 1, $size - $diameter - 1, $diameter, $diameter, 0, 90)
          $path.AddArc(0, $size - $diameter - 1, $diameter, $diameter, 90, 90)
          $path.CloseFigure()
          $graphics.SetClip($path)
          $scale = [Math]::Min($size / $source.Width, $size / $source.Height)
          $w = [int][Math]::Round($source.Width * $scale)
          $h = [int][Math]::Round($source.Height * $scale)
          $x = [int][Math]::Floor(($size - $w) / 2)
          $y = [int][Math]::Floor(($size - $h) / 2)
          $graphics.DrawImage($source, $x, $y, $w, $h)
          $graphics.ResetClip()
        } finally { $path.Dispose() }
        $ms = New-Object System.IO.MemoryStream
        try {
          $bitmap.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
          $images += ,$ms.ToArray()
        } finally { $ms.Dispose() }
      } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
      }
    }
  } finally { $source.Dispose() }

  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destPath) | Out-Null
  $fs = [System.IO.File]::Create($destPath)
  $bw = New-Object System.IO.BinaryWriter $fs
  try {
    $bw.Write([UInt16]0)
    $bw.Write([UInt16]1)
    $bw.Write([UInt16]$images.Count)
    $offset = 6 + (16 * $images.Count)
    for ($i = 0; $i -lt $images.Count; $i++) {
      $size = $sizes[$i]
      $bytes = [byte[]]$images[$i]
      $dim = if ($size -eq 256) { 0 } else { $size }
      $bw.Write([byte]$dim)
      $bw.Write([byte]$dim)
      $bw.Write([byte]0)
      $bw.Write([byte]0)
      $bw.Write([UInt16]1)
      $bw.Write([UInt16]32)
      $bw.Write([UInt32]$bytes.Length)
      $bw.Write([UInt32]$offset)
      $offset += $bytes.Length
    }
    foreach ($bytes in $images) { $bw.Write([byte[]]$bytes) }
  } finally {
    $bw.Dispose()
    $fs.Dispose()
  }
}

New-Item -ItemType Directory -Force -Path $out | Out-Null
if (Test-Path $logo) {
  New-IcoFromPng $logo $icon
  Write-Output "Generated icon: $icon"
}

$refs = @('/reference:System.dll','/reference:System.Core.dll','/reference:System.Drawing.dll','/reference:System.Windows.Forms.dll','/reference:System.Web.Extensions.dll')
$targets = @(
  @{Name='红绿灯.exe'; Target='winexe'},
  @{Name='codex-light-mxp.exe'; Target='exe'},
  @{Name='codex-light-hook-mxp.exe'; Target='exe'}
)
foreach ($t in $targets) {
  $exe = Join-Path $out $t.Name
  $iconArg = if (Test-Path $icon) { "/win32icon:$icon" } else { $null }
  if ($iconArg) {
    & $csc /nologo /target:$($t.Target) /platform:x64 /optimize+ /out:$exe $iconArg $refs $src
  } else {
    & $csc /nologo /target:$($t.Target) /platform:x64 /optimize+ /out:$exe $refs $src
  }
  if ($LASTEXITCODE -ne 0) { throw "Build failed for $($t.Name)" }
}
Write-Output "Built Windows artifacts in $out"






