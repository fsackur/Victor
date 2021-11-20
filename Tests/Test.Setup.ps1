
Get-Module Victor | Remove-Module -Force -ErrorAction SilentlyContinue
$Module = $PSScriptRoot |
    Split-Path |
    Join-Path -ChildPath Victor.psd1 |
    Import-Module -PassThru -ErrorAction Stop

function New-TestGitDir
{
    [CmdletBinding(DefaultParameterSetName = 'Init')]
    param
    (
        [Parameter(ParameterSetName = 'Clone', Mandatory)]
        [string]$CloneFrom,

        [Parameter(ParameterSetName = 'Clone')]
        [switch]$Bare
    )

    $ErrorActionPreference = 'Stop'

    if (-not $Global:__VICTOR_TEST_GIT_DIRS)
    {
        $Global:__VICTOR_TEST_GIT_DIRS = @()
    }

    $Temp = [IO.Path]::GetTempPath()
    $Name = [IO.Path]::GetRandomFileName()
    $Path = Join-Path $Temp $Name

    if ($PSCmdlet.ParameterSetName -eq 'Clone')
    {
        git clone $CloneFrom $Path '--shared' $(if ($Bare) {'bare'}) *>&1 | Write-Debug

        $Global:__VICTOR_TEST_GIT_DIRS += $Path

        $Path

    }
    else
    {
        New-Item $Path -ItemType Directory | Push-Location

        $Global:__VICTOR_TEST_GIT_DIRS += $Path

        try
        {
            git init                *>&1 | Write-Debug
            git checkout -b main    *>&1 | Write-Debug
            $Path
        }
        finally
        {
            Pop-Location
        }
    }
}


function Clear-TestGitDir
{
    [CmdletBinding()]
    param ()

    $ErrorActionPreference = 'Stop'

    $_PWD = $PWD -replace '^Microsoft.PowerShell.Core\\FileSystem::'
    if ($_PWD -in $Global:__VICTOR_TEST_GIT_DIRS)
    {
        Write-Warning "Not cleaning current location '$_PWD'."
    }

    @($Global:__VICTOR_TEST_GIT_DIRS) -ne $_PWD | Remove-Item -Recurse -Force
    $Global:__VICTOR_TEST_GIT_DIRS = $Global:__VICTOR_TEST_GIT_DIRS |
        Resolve-Path -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Path
}
