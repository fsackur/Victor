using namespace System.Management.Automation.Language

function Write-GitCommit
{
    [int]$Col = $MyInvocation.PositionMessage -replace '^At line:\d+ char:' -replace '(?s)\s.*'
    $Col--
    $Line = $MyInvocation.Line -replace "^.{$Col}$($MyInvocation.InvocationName) +"

    [Token[]]$Tokens = $null
    [void][Parser]::ParseInput($Line, [ref]$Tokens, [ref]$null)

    $SemicolonToken = $Tokens.Where({$_.Kind -eq 'Semi'}, 'First')
    if ($SemicolonToken)
    {
        $Line = $Line.Substring(0, $SemicolonToken.Extent.StartOffset)
    }

    [string]$Message = $Line


    git commit -m $Message
}
