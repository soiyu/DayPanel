# DayPanel Keystore Generation Helper Script
param(
  [string]$Alias = 'daypanel',
  [string]$OutputFilename = 'release.jks'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$targetDir = Join-Path $projectRoot '.local'
if (-not (Test-Path -LiteralPath $targetDir)) {
  New-Item -ItemType Directory -Force $targetDir | Out-Null
}
$outputPath = Join-Path $targetDir $OutputFilename

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  DayPanel Release Keystore Generator                    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Locate keytool
$keytool = $null
if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME 'bin/keytool.exe'))) {
  $keytool = Join-Path $env:JAVA_HOME 'bin/keytool.exe'
} else {
  $toolchainFile = Join-Path $projectRoot '.local/toolchain.json'
  if (Test-Path -LiteralPath $toolchainFile) {
    $tc = Get-Content -LiteralPath $toolchainFile -Raw | ConvertFrom-Json
    if ($tc.javaHome -and (Test-Path (Join-Path $tc.javaHome 'bin/keytool.exe'))) {
      $keytool = Join-Path $tc.javaHome 'bin/keytool.exe'
    }
  }
}

if (-not $keytool) {
  $keytoolCmd = Get-Command 'keytool' -ErrorAction SilentlyContinue
  if ($keytoolCmd) { $keytool = $keytoolCmd.Source }
}

if (-not $keytool) {
  Write-Host "[ERROR] keytool not found. Please ensure JDK 17 is configured in PATH or .local/toolchain.json." -ForegroundColor Red
  exit 1
}

Write-Host "[INFO] Using keytool: $keytool" -ForegroundColor Green

if (Test-Path -LiteralPath $outputPath) {
  Write-Host "[WARNING] $outputPath already exists!" -ForegroundColor Yellow
  $overwrite = Read-Host "Do you want to overwrite it? (y/N)"
  if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
    Write-Host "[INFO] Aborted without modifying existing keystore." -ForegroundColor Cyan
    exit 0
  }
}

$secPass = Read-Host -Prompt "Enter password for new keystore (at least 6 chars)" -AsSecureString
$plainPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPass))

if ($plainPass.Length -lt 6) {
  Write-Host "[ERROR] Password must be at least 6 characters long." -ForegroundColor Red
  exit 1
}

$dname = "CN=DayPanel, OU=Mobile, O=DayPanel, L=Beijing, ST=Beijing, C=CN"

Write-Host "[INFO] Generating keystore at: $outputPath" -ForegroundColor Cyan
& $keytool -genkeypair -v `
  -keystore $outputPath `
  -alias $Alias `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -storepass $plainPass `
  -keypass $plainPass `
  -dname $dname `
  -storetype JKS

if ($LASTEXITCODE -ne 0) {
  Write-Host "[ERROR] Keystore generation failed." -ForegroundColor Red
  exit $LASTEXITCODE
}

Write-Host ""
Write-Host "[SUCCESS] Keystore successfully created at: $outputPath" -ForegroundColor Green
Write-Host ""
Write-Host "You can now update your .local/play-release.properties with:" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------"
Write-Host "storeFile=../.local/$OutputFilename"
Write-Host "storePassword=$plainPass"
Write-Host "keyAlias=$Alias"
Write-Host "keyPassword=$plainPass"
Write-Host "----------------------------------------------------------"
