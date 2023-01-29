using namespace System.Collections.Generic

function Get-GitLog
{
    [CmdletBinding(DefaultParameterSetName = 'SinceLastMerge')]
    param
    (
        [Parameter(ParameterSetName = 'Path', Mandatory)]
        [string]$Path,

        [Parameter(ParameterSetName = 'Path')]
        [switch]$Follow,

        [Parameter(ParameterSetName = 'SinceLastMerge')]
        [switch]$SinceLastMerge,

        [Parameter(ParameterSetName = 'ByCount', Position = 0)]
        [ValidateRange(1, 5000)]
        [int]$Count = 30,

        [Parameter(ParameterSetName = 'FromRef')]
        [Parameter(ParameterSetName = 'Path')]
        [string]$From,

        [Parameter()]
        [switch]$SortDescending,

        [Parameter()]
        [ValidateSet('Relative', 'DateTime')]
        [string]$DateFormat = 'Relative'
    )

    $AsDatetime = $DateFormat -eq 'DateTime'

    if ($PSCmdlet.ParameterSetName -eq 'SinceLastMerge')
    {
        $From = git log --merges -n 1 --format=%h

        if (-not $From)
        {
            $From = git rev-list --max-parents=0 HEAD --abbrev-commit | Select-Object -First 1
        }
    }


    $LogArgs = [List[string]]::new()
    $LogArgs.Add("log")

    if ($From)
    {
        $LogArgs.Add("$From..HEAD")
    }
    else
    {
        $LogArgs.Add("-n $Count")
    }

    if ($SortDescending)
    {
        $LogArgs.Add("--reverse")
    }

    # https://git-scm.com/docs/git-log#_pretty_formats
    $Format = [ordered]@{
        Id         = '%h'
        Author     = '%an'
        AuthorDate = if ($AsDatetime) {'%ai'} else {'%ar'}
        Summary    = '%s'
    }
    $OutputProperties = @($Format.Keys)

    $Delim        = [char]0x2007    # unusual space char that we don't expect to find in git output
    $FormatString = $Format.Values -join $Delim
    $LogArgs.Add("--pretty=format:$FormatString")

    if ($Follow)
    {
        $LogArgs.Add("--follow")
    }

    if ($Path)
    {
        $LogArgs.Add("--name-only")
        $LogArgs.Add("-p")
        $LogArgs.Add($Path)
    }


    # Do the thing
    $CommitLines = & git $LogArgs

    $Commits = $CommitLines | ConvertFrom-Csv -Delimiter $Delim -Header $OutputProperties

    if ($Path)
    {
        # Hack until I can get rid of diff output entirely
        $Commits = $Commits | Where-Object -Property Author
    }

    if ($AsDatetime)
    {
        $Commits | ForEach-Object {$_.AuthorDate = [datetime]$_.AuthorDate}
    }

    $Commits
}
