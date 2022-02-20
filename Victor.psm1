[CmdletBinding()]
param
(
    [switch]$NoAlias = $env:VICTOR_NO_PS_ALIAS
)

Get-ChildItem $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue | ForEach-Object {. $_.FullName}
Get-ChildItem $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue | ForEach-Object {. $_.FullName}

if (-not $NoAlias)
{
    Set-Alias a Victor\Add-GitFile
    Set-Alias amend Victor\Update-GitCommit
    Set-Alias c Victor\Write-GitCommit
    Set-Alias ggl Victor\Get-GitLog
    Set-Alias rebase Victor\Invoke-GitRebase
    Set-Alias rst Victor\Reset-Git
}
