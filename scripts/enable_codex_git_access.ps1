$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$gitPath = Join-Path $projectRoot ".git"
$computerName = $env:COMPUTERNAME
$codexUser = "$computerName\codexsandboxoffline"
$codexGroup = "$computerName\CodexSandboxUsers"

if (-not (Test-Path $gitPath)) {
  throw "Git folder not found at $gitPath"
}

Write-Host "Granting Codex write access to this repository Git folder..."

$denyIdentities = icacls $gitPath |
  Select-String "\(DENY\)" |
  ForEach-Object {
    if ($_.Line -match "(S-\d-\d+(?:-\d+)+):.*\(DENY\)") {
      $matches[1].Trim()
    }
  } |
  Where-Object { $_ } |
  Sort-Object -Unique

foreach ($identity in $denyIdentities) {
  Write-Host "Removing explicit deny rule for $identity..."
  & icacls $gitPath /remove:d "*$identity" /T
}

icacls $gitPath /grant "${codexUser}:(OI)(CI)F" /T
icacls $gitPath /grant "${codexGroup}:(OI)(CI)F" /T

$testFile = Join-Path $gitPath "codex_write_test.tmp"
Set-Content -Path $testFile -Value "ok"
Remove-Item -Path $testFile -Force

Write-Host "Codex Git access is enabled for this repository."
Write-Host "You can now ask Codex to create commits from this project."
