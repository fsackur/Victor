using namespace System.Collections.Generic

function Get-GitLog
{
    [CmdletBinding()]
    param
    (
        [int]$Count = 30
    )


    $LogArgs = [List[string]]::new()
    $LogArgs.Add("log")

    $LogArgs.Add("-n $Count")

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
