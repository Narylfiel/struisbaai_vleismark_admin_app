# Edge + RLS phase gate — static checks (run from repo / CI after enabling USE_EDGE_PIPELINE).
# Does not replace staging E2E smoke tests or live anon policy snapshots.
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
Write-Host "Workspace root: $root"

$patterns = @(
  @{ Name = "POS direct transactions insert (should be behind !canUseEdgePipeline)"; Path = "pos_app\lib"; Regex = "\.from\(['\`"]transactions['\`"]\)\s*\.insert" }
  @{ Name = "POS direct transaction_items insert"; Path = "pos_app\lib"; Regex = "\.from\(['\`"]transaction_items['\`"]\)\s*\.insert" }
  @{ Name = "POS direct stock_movements insert"; Path = "pos_app\lib"; Regex = "\.from\(['\`"]stock_movements['\`"]\)\s*\.insert" }
  @{ Name = "Admin direct ledger_entries insert"; Path = "admin_app\lib"; Regex = "\.from\(['\`"]ledger_entries['\`"]\)\s*\.insert" }
)

$rg = Get-Command rg -ErrorAction SilentlyContinue
if (-not $rg) {
  Write-Warning "ripgrep (rg) not on PATH; install or run equivalent greps manually."
  exit 0
}

foreach ($p in $patterns) {
  Write-Host "`n--- $($p.Name) ---"
  Push-Location $root
  try {
    rg --line-number $p.Regex $p.Path 2>$null
  } finally {
    Pop-Location
  }
}

Write-Host "`nReview: each hit should be in a branch guarded by !EdgePipelineConfig.canUseEdgePipeline (legacy path)."
Write-Host "After migration 060, legacy paths that rely on anon writes will fail until removed or migrated."
