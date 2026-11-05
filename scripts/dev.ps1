param(
  [ValidateSet('doctor','pub','format','analyze','test','assemble','verify','run')]
  [string]$Command = 'verify',
  [string[]]$Extra = @()
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$configFile = Join-Path $projectRoot '.local/toolchain.json'
if (-not (Test-Path -LiteralPath $configFile)) { throw 'Configure .local/toolchain.json using docs/development/BUILD.md.' }
$config = Get-Content -LiteralPath $configFile -Raw | ConvertFrom-Json
$flutterSdk = $config.flutterSdk
if (-not [IO.Path]::IsPathRooted($flutterSdk)) { $flutterSdk = Join-Path $projectRoot $flutterSdk }
$flutter = Join-Path $flutterSdk 'bin/flutter.bat'
$dart = Join-Path $flutterSdk 'bin/dart.bat'
$env:JAVA_HOME = $config.javaHome
$env:ANDROID_HOME = $config.androidSdk
$env:ANDROID_SDK_ROOT = $config.androidSdk
$env:PUB_CACHE = Join-Path $projectRoot '.local/pub-cache'
$env:GRADLE_USER_HOME = Join-Path $projectRoot '.local/gradle'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:DART_SUPPRESS_ANALYTICS = 'true'
# Flutter prefers its settings (then Android Studio) over JAVA_HOME. Isolate
# Windows tool settings so the configured JDK is honored without global edits.
$env:APPDATA = Join-Path $projectRoot '.local/tool-settings'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
@{'jdk-dir'=$config.javaHome; 'android-sdk'=$config.androidSdk} | ConvertTo-Json |
  Set-Content -LiteralPath (Join-Path $env:APPDATA '.flutter_settings') -Encoding utf8
$env:PATH = "$(Join-Path $env:JAVA_HOME 'bin');$(Join-Path $flutterSdk 'bin');$env:PATH"
function Invoke-Flutter([string[]]$Arguments) {
  & $flutter --suppress-analytics @Arguments
  if ($LASTEXITCODE -ne 0) { throw "Flutter command failed: $Arguments (exit $LASTEXITCODE)" }
}
Push-Location $projectRoot
try {
  switch ($Command) {
    'doctor' { Invoke-Flutter @('doctor','-v') }
    'pub' { Invoke-Flutter @('pub','get'); Invoke-Flutter @('gen-l10n') }
    'format' { & $dart format lib test; if ($LASTEXITCODE -ne 0) { throw 'Format failed' } }
    'analyze' { Invoke-Flutter @('analyze') }
    'test' { Invoke-Flutter (@('test') + $Extra) }
    'assemble' { Invoke-Flutter (@('build','apk','--debug') + $Extra) }
    'run' { Invoke-Flutter (@('run') + $Extra) }
    'verify' {
      Invoke-Flutter @('pub','get'); Invoke-Flutter @('gen-l10n')
      & $dart format --output=none --set-exit-if-changed lib test
      if ($LASTEXITCODE -ne 0) { throw 'Run scripts/dev.ps1 format first' }
      Invoke-Flutter @('analyze'); Invoke-Flutter @('test'); Invoke-Flutter @('build','apk','--debug')
    }
  }
} finally { Pop-Location }
