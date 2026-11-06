# Original two-note, short completion sound. No recordings or third-party audio.
# Reproducible mono PCM, 22050 Hz, 0.22 seconds. Run from any directory.
$ErrorActionPreference = 'Stop'
$output = Join-Path (Split-Path -Parent $PSScriptRoot) 'android/app/src/main/res/raw/daypanel_complete.wav'
New-Item -ItemType Directory -Force (Split-Path -Parent $output) | Out-Null
$sampleRate = 22050
$sampleCount = [int]($sampleRate * .22)
$stream = [IO.File]::Create($output)
$writer = [IO.BinaryWriter]::new($stream)
try {
  $writer.Write([Text.Encoding]::ASCII.GetBytes('RIFF')); $writer.Write([int](36 + 2 * $sampleCount))
  $writer.Write([Text.Encoding]::ASCII.GetBytes('WAVEfmt ')); $writer.Write([int]16)
  $writer.Write([int16]1); $writer.Write([int16]1); $writer.Write([int]$sampleRate)
  $writer.Write([int]($sampleRate * 2)); $writer.Write([int16]2); $writer.Write([int16]16)
  $writer.Write([Text.Encoding]::ASCII.GetBytes('data')); $writer.Write([int]($sampleCount * 2))
  for ($i=0; $i -lt $sampleCount; $i++) {
    $time = $i / [double]$sampleRate
    $a = [Math]::Sin([Math]::PI * [Math]::Min(1, $time / .15))
    $value = if($time -lt .15) { .12 * $a * $a * [Math]::Sin(2 * [Math]::PI * 660 * $time) } else { 0 }
    if($time -gt .06) {
      $b = [Math]::Sin([Math]::PI * ($time - .06) / .16)
      $value += .10 * $b * $b * [Math]::Sin(2 * [Math]::PI * 880 * ($time - .06))
    }
    $writer.Write([int16][Math]::Round(32767 * $value))
  }
} finally { $writer.Dispose(); $stream.Dispose() }
