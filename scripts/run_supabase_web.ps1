$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $repoRoot '.env.local'

if (-not (Test-Path -LiteralPath $envFile)) {
  throw "Missing .env.local. Create it with SUPABASE_URL and SUPABASE_ANON_KEY."
}

$values = @{}

Get-Content -LiteralPath $envFile | ForEach-Object {
  $line = $_.Trim()

  if ($line -eq '' -or $line.StartsWith('#')) {
    return
  }

  $parts = $line.Split('=', 2)

  if ($parts.Count -eq 2) {
    $values[$parts[0].Trim()] = $parts[1].Trim()
  }
}

if (-not $values.ContainsKey('SUPABASE_URL')) {
  throw 'SUPABASE_URL is missing in .env.local.'
}

if (-not $values.ContainsKey('SUPABASE_ANON_KEY')) {
  throw 'SUPABASE_ANON_KEY is missing in .env.local.'
}

if (-not $values.ContainsKey('STUDENT_CODE_SALT')) {
  throw 'STUDENT_CODE_SALT is missing in .env.local.'
}

Set-Location -LiteralPath $repoRoot

& C:\flutter\bin\flutter.bat run -d chrome `
  "--dart-define=SUPABASE_URL=$($values['SUPABASE_URL'])" `
  "--dart-define=SUPABASE_ANON_KEY=$($values['SUPABASE_ANON_KEY'])" `
  "--dart-define=STUDENT_CODE_SALT=$($values['STUDENT_CODE_SALT'])"
