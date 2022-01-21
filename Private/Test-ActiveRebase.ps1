function Test-ActiveRebase
{
    [OutputType([bool])]
    [CmdletBinding()]
    param ()

    if (Test-Path (git rev-parse --git-path rebase-merge))
    {
        return $true
    }

    if (Test-Path (git rev-parse --git-path rebase-apply))
    {
        return $true
    }

    return $false
}
