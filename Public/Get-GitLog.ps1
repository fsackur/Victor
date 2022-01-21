using namespace System.Collections.Generic

function Get-GitLog
{
    [CmdletBinding(DefaultParameterSetName = 'SinceLastMerge')]
    param
    (
        [Parameter(ParameterSetName = 'SinceLastMerge')]
        [switch]$SinceLastMerge,

        [Parameter(ParameterSetName = 'ByCount', Position = 0)]
        [ValidateRange(1, 5000)]
        [int]$Count = 30,

        [Parameter(ParameterSetName = 'FromRef')]
        [string]$From
    )

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

    # https://git-scm.com/docs/git-log#_pretty_formats
    $Format = [ordered]@{
        Id        = '%h'
        Author    = '%an'
        UpdatedAt = '%ar'
        Summary   = '%s'
    }
    $OutputProperties = @($Format.Keys)

    $Delim        = [char]0x2007    # unusual space char that we don't expect to find in git output
    $FormatString = $Format.Values -join $Delim
    $LogArgs.Add("--pretty=format:$FormatString")


    # Do the thing
    $CommitLines = & git $LogArgs

    $CommitLines | ConvertFrom-Csv -Delimiter $Delim -Header $OutputProperties
}
