function Reset-Git
{
    [CmdletBinding(DefaultParameterSetName = 'ByRef')]
    param
    (
        [Parameter()]
        [switch]$Hard,

        [Parameter(ParameterSetName = 'ByCount', Position = 0)]
        [ValidateRange(0, 9999)]
        [int]$Count = 0,

        [Parameter(ParameterSetName = 'ByRef', Position = 0)]
        [string]$Commit
    )


    # Handle commit IDs that are all digits; note that 123e123 is an int literal!
    if ($Commit -and $Commit.Length -lt 5 -and $Commit -match '^\d+$')
    {
        $Count  = [int]$Commit
        $Commit = $null
    }


    $ResetArgs = @('reset', '-q')

    if ($Hard)
    {
        git add *   # Otherwise, untracked files are not reset
        $ResetArgs += '--hard'
    }

    if ($Commit)
    {
        $ResetArgs += $Commit
    }
    else
    {
        $ResetArgs += "HEAD~$Count"
    }


    git $ResetArgs
}
