Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$cfgPath  = Join-Path $repoRoot ".data\subs.json"

if (Test-Path $cfgPath) {
  $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
  Write-Host "Configured subscriptions (.data/subs.json):" -ForegroundColor Cyan
  $cfg.subscriptions.PSObject.Properties | ForEach-Object {
    $k = $_.Name
    $v = $_.Value
    "{0,-6}  {1,-24}  {2}" -f $k, $v.name, $v.id
  }
  Write-Host "`nDefault key: $($cfg.default)" -ForegroundColor Cyan
} else {
  Write-Host "No .data/subs.json found. Create it from .data/subs.example.json" -ForegroundColor Yellow
}

Write-Host "`nAzure CLI active subscription:" -ForegroundColor Cyan
az account show --query "{name:name, id:id, user:user.name}" -o table
