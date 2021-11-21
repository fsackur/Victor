function Get-GitBranch
{
    [CmdletBinding()]
    param
    (
        [switch]$Active,

        [switch]$NameOnly
    )

    # https://git-scm.com/docs/git-for-each-ref#_field_names
    $Format = [ordered]@{
        Active       = '%(HEAD)'
        Name         = '%(refname:short)'
        Upstream     = '%(upstream:short)'
        TrackingInfo = '%(upstream:track,nobracket)'
        Id           = '%(objectname:short)'
    }

    if ($NameOnly)
    {
        if ($Active)
        {
            return git name-rev HEAD --name-only
        }

        return git for-each-ref --format=$($Format.Name) refs/heads
    }
    else
    {
        $OutputProperties = @($Format.Keys)

        $Delim        = [char]31    # non-printing char that we don't expect to find in git output
        $FormatString = $Format.Values -join $Delim

        $BranchLines = git for-each-ref --format=$FormatString refs/heads

        $Branches = $BranchLines |
            ConvertFrom-Csv -Delimiter $Delim -Header $OutputProperties

        $ActiveBranch = $Branches |
            Where-Object {$_.Active} |
            ForEach-Object {$_.Active = $true; $_}

        if ($Active)
        {
            $ActiveBranch
        }
        else
        {
            $Branches
        }
    }
}
