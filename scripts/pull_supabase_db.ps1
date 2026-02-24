# Pull remote Supabase schema into local migrations (admin_app/supabase/migrations).
# Reads password from admin_app/supabase/.temp/db-password.txt.
# Requires: Docker Desktop running (supabase db pull uses a shadow database).
# Usage: .\pull_supabase_db.ps1

$ErrorActionPreference = "Stop"
$adminApp = Join-Path $PSScriptRoot "..\admin_app"
$tempDir = Join-Path $adminApp "supabase\.temp"
$pwFile = Join-Path $tempDir "db-password.txt"

if (-not (Test-Path $pwFile)) {
    Write-Error "No password found. Add $pwFile with the database password on one line (Supabase Dashboard -> Project Settings -> Database)."
    exit 1
}
$dbPassword = (Get-Content $pwFile -Raw).Trim()

# Project ref matches .env SUPABASE_URL (nasfakcqzmpfcpqttmti)
$poolerUrl = "postgresql://postgres.nasfakcqzmpfcpqttmti:" + [Uri]::EscapeDataString($dbPassword) + "@aws-1-eu-west-1.pooler.supabase.com:5432/postgres"

Push-Location $adminApp
try {
    Write-Host "Pulling remote database schema..."
    & supabase db pull --db-url $poolerUrl
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "Schema pulled successfully."
} finally {
    Pop-Location
}
