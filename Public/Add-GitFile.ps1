using namespace System.Collections.Generic

function Add-GitFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path = '*',

        [switch]$Patch
    )

    $AddArgs = [List[string]]::new()
    $AddArgs.Add('add')
    $AddArgs.AddRange($Path)

    if ($Patch)
    {
        $AddArgs.Add('--patch')
    }

    git $AddArgs

    git status -v
    git status
}


Register-ArgumentCompleter -CommandName Add-GitFile -ParameterName Path -ScriptBlock {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    @(git status -s) -replace '^...' -like "*$wordToComplete*"
}
