
Get-ChildItem $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue | ForEach-Object {. $_.FullName}
Get-ChildItem $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue | ForEach-Object {. $_.FullName}

Set-Alias a Add-GitFile
Set-Alias amend Update-GitCommit
Set-Alias c Write-GitCommit
Set-Alias ggl Get-GitLog
Set-Alias rebase Invoke-GitRebase
Set-Alias rst Reset-Git
