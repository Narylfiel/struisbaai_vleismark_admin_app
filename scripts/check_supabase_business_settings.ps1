# Check Supabase business_settings table (list public tables + describe business_settings)
# Requires: credentials JSON with "url" and DATABASE PASSWORD for psql (Supabase Dashboard -> Project Settings -> Database).
# Note: anon_key and service_role_key are API JWTs; psql needs the actual DB password.

param(
    [Parameter(Mandatory=$false)]
    [string]$CredsFile = "C:\Users\grize\AppData\Local\Temp\credentials.json"
)

if (-not (Test-Path $CredsFile)) {
    Write-Host "Credentials file not found: $CredsFile"
    Write-Host "Usage: .\check_supabase_business_settings.ps1 -CredsFile 'C:\path\to\temp\credentials.json'"
    exit 1
}

$json = Get-Content $CredsFile -Raw | ConvertFrom-Json
$supabaseUrl = $json.url
if (-not $supabaseUrl) { $supabaseUrl = $json.SupabaseUrl }

# Database password (required for psql)
$dbPassword = $json.password
if (-not $dbPassword) { $dbPassword = $json.db_password }
if (-not $dbPassword) { $dbPassword = $json.database_password }
if (-not $dbPassword) {
    Write-Warning "No password/db_password/database_password in JSON. anon_key/service_role_key will NOT work for psql."
    $dbPassword = if ($json.service_role_key) { $json.service_role_key } else { $json.anon_key }
}

# Supabase direct Postgres: host = db.<project_ref>.supabase.co, database = postgres (not from API URL path)
$uri = [Uri]$supabaseUrl
$projectRef = $uri.Host -replace '\.supabase\.co$',''
$dbHost = "db.$projectRef.supabase.co"
$dbPort = 5432
$dbName = "postgres"
$dbUser = "postgres"

Write-Host "Host=$dbHost Port=$dbPort Db=$dbName User=$dbUser"
$env:PGPASSWORD = $dbPassword
psql -h $dbHost -p $dbPort -d $dbName -U $dbUser -c "\dt public.*" -c "\d+ public.business_settings"
