# Dump remote Supabase public schema with pg_dump (no Docker).
# Reads password from admin_app/supabase/.temp/db-password.txt.
# Output: admin_app/supabase/.temp/pulled_schema.sql
# Requires: PostgreSQL client tools (pg_dump) in PATH.
# Usage: .\pg_dump_schema.ps1

$ErrorActionPreference = "Stop"
$adminApp = Join-Path $PSScriptRoot "..\admin_app"
$tempDir = Join-Path $adminApp "supabase\.temp"
$pwFile = Join-Path $tempDir "db-password.txt"
$outFile = Join-Path $tempDir "pulled_schema.sql"

if (-not (Test-Path $pwFile)) {
    Write-Error "No password found. Add $pwFile with the database password on one line."
    exit 1
}
$dbPassword = (Get-Content $pwFile -Raw).Trim()

# Project ref from .env SUPABASE_URL; pooler host
$connUrl = "postgresql://postgres.nasfakcqzmpfcpqttmti:" + [Uri]::EscapeDataString($dbPassword) + "@aws-1-eu-west-1.pooler.supabase.com:5432/postgres"

if (-not (Get-Command pg_dump -ErrorAction SilentlyContinue)) {
    Write-Error "pg_dump not found. Install PostgreSQL client tools and ensure pg_dump is in PATH."
    exit 1
}

# Ensure output dir exists
$null = New-Item -ItemType Directory -Force -Path $tempDir

Write-Host "Dumping public schema to $outFile ..."
& pg_dump $connUrl --schema=public --schema-only --no-owner --no-privileges -f $outFile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Schema dumped successfully to $outFile"
