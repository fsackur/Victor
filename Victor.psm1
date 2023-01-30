[Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingCmdletAliases', '')]
[CmdletBinding()]
param
(
    [switch]$NoAlias = $env:VICTOR_NO_PS_ALIAS
)

$DllNames = 'LibGit2Sharp.dll', 'Victor.dll'
$DllPaths = $DllNames | ForEach-Object {Join-Path $PSScriptRoot $_}
#region Convenience for devs
$MissingDlls = $DllPaths | Where-Object {-not (Test-Path $_)}
if ($MissingDlls)
{
    if ($PSVersionTable.PSVersion.Major -le 5 -or $IsWindows)
    {
        $ParentProcessId = (Get-CimInstance -Query "SELECT ParentProcessId FROM Win32_Process WHERE ProcessId = $PID").ParentProcessId
        $ParentName      = (Get-CimInstance -Query "SELECT Name FROM Win32_Process WHERE ProcessId = $ParentProcessId").Name -replace '\.exe$'
    }
    else
    {
        $ParentName      = @()
        $ParentProcessId = $PID
        while ($ParentProcessId)
        {
            # ps --tree not installed by default on OSX
            $ParentName     += ps -p $ParentProcessId -o comm | select -Skip 1 -First 1 | Split-Path -Leaf
            $ParentProcessId = ps -p $ParentProcessId -o ppid | select -Skip 1 -First 1
        }
    }

    if (-not ($ParentName -eq 'vsdbg' -or $ParentName -eq 'Code'))
    {
        throw "DLL not found."
    }

    $BuildPath = [IO.Path]::Combine($PSScriptRoot, 'Victor', 'bin', 'Debug', 'netstandard2.0', 'publish')
    $DllPaths  = $DllNames | ForEach-Object {Join-Path $BuildPath $_}
}
#endregion Convenience for devs
$DllPaths | ForEach-Object {Import-Module $_ -ErrorAction Stop}

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
