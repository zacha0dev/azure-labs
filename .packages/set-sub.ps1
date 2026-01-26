param(
  [Parameter(Mandatory=$true)]
  [ValidateSet("lab","prod")]
  [string]$Key
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# repo root is one level up from .packages
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$cfgPath  = Join-Path $repoRoot ".data\subs.json"

if (-not (Test-Path $cfgPath)) {
  throw "Missing $cfgPath. Create it from .data/subs.example.json and add your real subscription IDs."
}

$cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
$sub = $cfg.subscriptions.$Key
if (-not $sub) { throw "Unknown key '$Key' in .data/subs.json" }

Write-Host "Switching Azure CLI subscription -> $Key ($($sub.name)) [$($sub.id)]" -ForegroundColor Cyan
az account set --subscription $sub.id | Out-Null

# persist default for scripts/setup
$cfg.default = $Key
$cfg | ConvertTo-Json -Depth 10 | Set-Content $cfgPath -Encoding UTF8

$active = az account show --query "{name:name, id:id}" -o json | ConvertFrom-Json
Write-Host "Active: $($active.name) [$($active.id)]" -ForegroundColor Green
