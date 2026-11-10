$ErrorActionPreference='Stop'
$releaseRoot=Split-Path -Parent $PSScriptRoot
$releaseFile=Join-Path $releaseRoot '.local/play-release.properties'
if(!(Test-Path -LiteralPath $releaseFile)){throw 'Release blocked: create .local/play-release.properties from docs/release/play-release.properties.example using your real Play and signing details.'}
$releaseValues=Get-Content -LiteralPath $releaseFile -Raw | ConvertFrom-StringData
$releaseRequired=@('applicationId','productId','billingPublicKey','storeFile','storePassword','keyAlias','keyPassword','privacyUrl','supportEmail')
$releaseMissing=@($releaseRequired | Where-Object {[string]::IsNullOrWhiteSpace($releaseValues[$_])})
if($releaseMissing.Count){throw ('Release blocked: missing fields '+($releaseMissing -join ', '))}
if($releaseValues.applicationId.EndsWith('.debug')){throw 'Release applicationId must not be the debug application.'}
if($releaseValues.privacyUrl -notmatch '^https://' -or $releaseValues.privacyUrl -match 'example\.|localhost|TODO|CHANGE_ME'){throw 'A real public HTTPS privacy policy is required.'}
if($releaseValues.supportEmail -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$' -or $releaseValues.supportEmail -match 'example\.|TODO'){throw 'A real support email is required.'}
$releaseKeyPath=$releaseValues.storeFile
if(![IO.Path]::IsPathRooted($releaseKeyPath)){$releaseKeyPath=Join-Path (Join-Path $releaseRoot 'android') $releaseKeyPath}
if(!(Test-Path -LiteralPath $releaseKeyPath -PathType Leaf)){throw 'The configured signing keystore does not exist.'}
try{[void][Convert]::FromBase64String($releaseValues.billingPublicKey)}catch{throw 'Play billing public key must be the real Base64 key from Play Console.'}
'Local release fields are present. This does not prove Play identity, product availability, public URL reachability, signing-key ownership, review approval or payment acceptance. Run the documented Play license tests before release.'
