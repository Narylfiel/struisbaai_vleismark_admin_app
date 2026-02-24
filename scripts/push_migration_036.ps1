# Push migration 036 to Supabase (business_accounts, audit_log, message_logs)
# Reads credentials from admin_app/supabase/.temp (credentials.json or db-password.txt).
# Usage: .\push_migration_036.ps1

$ErrorActionPreference = "Stop"
$adminApp = Join-Path $PSScriptRoot "..\admin_app"
$tempDir = Join-Path $adminApp "supabase\.temp"

# Resolve password from .temp: credentials.json (password/db_password/database_password) or db-password.txt (plain)
$dbPassword = $null
$credsJson = Join-Path $tempDir "credentials.json"
$pwFile = Join-Path $tempDir "db-password.txt"

if (Test-Path $credsJson) {
    $json = Get-Content $credsJson -Raw | ConvertFrom-Json
    $dbPassword = $json.password
    if (-not $dbPassword) { $dbPassword = $json.db_password }
    if (-not $dbPassword) { $dbPassword = $json.database_password }
}
if (-not $dbPassword -and (Test-Path $pwFile)) {
    $dbPassword = (Get-Content $pwFile -Raw).Trim()
}

if (-not $dbPassword) {
    Write-Error "No password found. Add one of: (1) $credsJson with key 'password' or 'db_password', or (2) $pwFile with the database password on one line (Supabase Dashboard -> Project Settings -> Database)."
    exit 1
}

Push-Location $adminApp
try {
    Write-Host "Pushing migrations to linked Supabase project..."
    # Pooler URL with password (user is postgres.PROJECT_REF)
    $poolerUrl = "postgresql://postgres.nasfakcqzmpfcpqttmti:" + [Uri]::EscapeDataString($dbPassword) + "@aws-1-eu-west-1.pooler.supabase.com:5432/postgres"
    & supabase db push --db-url $poolerUrl
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "Migrations pushed successfully."
} finally {
    Pop-Location
}
