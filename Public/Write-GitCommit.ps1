using namespace System.Collections.Generic

function Write-GitCommit
{
    [CmdletBinding()]
    param
    (
	    [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(DontShow, ValueFromRemainingArguments)]
        [string[]]$MessageParts
    )

    if ($MessageParts) {$Message = "$Message $MessageParts"}

    git commit -m $Message
}
