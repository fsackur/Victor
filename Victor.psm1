
Get-ChildItem $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue | ForEach-Object {. $_.FullName}
Get-ChildItem $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue | ForEach-Object {. $_.FullName}
