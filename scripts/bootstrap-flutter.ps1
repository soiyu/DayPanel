param()
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$localDir = Join-Path $projectRoot '.local'
$archive = Join-Path $localDir 'flutter_windows_3.47.9-stable.zip'
$destination = Join-Path $localDir 'sdk'
New-Item -ItemType Directory -Force $destination | Out-Null
if (-not (Test-Path -LiteralPath $archive) -or (Get-Item -LiteralPath $archive).Length -lt 1939451626) {
  & curl.exe --fail --location --continue-at - --retry 6 --retry-delay 2 --connect-timeout 20 --silent --show-error 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.47.9-stable.zip' -o $archive
  if ($LASTEXITCODE -ne 0) { throw 'Download failed; run this script again to resume.' }
}
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'd8e2b5977e09082c6440f89dc1aa887b94c8fbcc3b39222797046295a3f68a9e') {
  throw 'Archive SHA-256 mismatch. Inspect the incomplete download before retrying.'
}
if (-not (Test-Path -LiteralPath (Join-Path $destination 'flutter/bin/flutter.bat'))) {
  & tar.exe -xf $archive -C $destination
  if ($LASTEXITCODE -ne 0) { throw 'SDK extraction failed' }
}
Write-Output 'Flutter SDK is available in .local/sdk/flutter. Configure JDK and Android SDK paths next.'
