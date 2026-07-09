param(
  [string]$Message = "Fix assigned activity links and listening audio paths"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$files = @(
  "lib/data/listening_data.dart",
  "lib/models/listening_exercise.dart",
  "lib/screens/teacher/teacher_assign_activity_screen.dart",
  "scripts/enable_codex_git_access.ps1",
  "scripts/save_latest_fixes.ps1"
)

Write-Host "Saving latest TASILLA fixes to Git..."

git add -- $files
git commit -m $Message
git status --short

Write-Host "Done."
