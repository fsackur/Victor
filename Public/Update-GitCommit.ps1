function Update-GitCommit
{
    <#
        .SYNOPSIS
        Amends an existing commit.

        .DESCRIPTION
        By default, this command will update the last commit using git commit --amend.

        You can also provide the commit message of an existing commit to be amended. This command
        will, by default, immediately rewrite the git history to apply the change to the specified
        commit.

        > Note that this may also apply other fixups and squashes that have not yet been squashed.

        If there are changed files already in the index, this command will commit only those files.
        Otherwise, all changed files in the working tree are added and committed.

        .PARAMETER Reword
        Specifies to change the commit message of the last commit. Only the message is changed;
        files in the index and working tree are left uncommitted.

        .PARAMETER Message
        Provide the message of an existing commit to be amended.

        When used with the Reword parameter, this message becomes the new message for the commit.

        .PARAMETER NoRebase
        Specifies to create a fixup commit but not to apply it to the historical commit. By default,
        when fixing up a commit, a non-interactive rebase will be performed to apply the fixup.

        .OUTPUTS
        [void]
    #>

    [CmdletBinding(DefaultParameterSetName = 'Amend')]
    param
    (
        [Parameter(ParameterSetName = 'Reword', Mandatory)]
        [switch]$Reword,

        [Parameter(ParameterSetName = 'Reword', Mandatory, Position = 0)]
        [Parameter(ParameterSetName = 'Fixup', Mandatory, Position = 0)]
        [Parameter(ParameterSetName = 'FixupAndRebase', Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(ParameterSetName = 'Fixup', Mandatory)]
        [switch]$NoRebase
    )


    [ValidateSet('Amend', 'Reword', 'Fixup', 'FixupAndRebase')]$Action = $PSCmdlet.ParameterSetName


    $Status = Get-GitStatus
    $IndexFiles = $Status | Where-Object Index | Select-Object -ExpandProperty File

    if (-not $Status -and -not $Reword)
    {
        throw "Nothing to commit"
    }

    if (-not $IndexFiles)
    {
        Write-Warning "Nothing in index; auto-staging all files"
        git add *
    }


    if ($Message -eq (Get-GitLog 1 | Select-Object -ExpandProperty Summary))
    {
        $Action = 'Amend'
    }

    $EscapedMessage = $Message -replace '"', '\"'


    if ($Action -eq 'Amend')
    {
        git commit --amend --no-edit | Out-Null
    }
    elseif ($Action -eq 'Reword')
    {
        git stash --all | Out-Null
        git commit --amend --no-edit -m $EscapedMessage | Out-Null
        git stash pop --index | Out-Null
    }
    else
    {
        git commit -m "fixup! $EscapedMessage" | Out-Null
        $ShouldRebase = $? -and $Action -eq 'FixupAndRebase'
    }


    if ($? -and $Action -eq 'FixupAndRebase')
    {
        $History = Get-GitLog | Select-Object -ExpandProperty Summary
        $Message = $History[0] -replace '^fixup! '
        $CountToRebase = $History.IndexOf($Message)
        if ($CountToRebase -gt 1)
        {
            Invoke-GitRebase -Count ($CountToRebase + 1)
        }
        else
        {
            # Could happen if:
            # - user specifies message manually, but it's before Get-GitLog's default limit
            # - argument completer no longer current with this command
            # - message gets garbled and doesn't match history exactly (then it would probably not rebase properly anyway)
            throw "Not rebasing to apply fixup; the target commit for the fixup is not within the default history search limit. Please rebase manually to apply the fixup."
        }
    }
}


Register-ArgumentCompleter -CommandName Update-GitCommit -ParameterName Message -ScriptBlock {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $Completions = if ($fakeBoundParameters.Reword)
    {
        $LastCommit = Get-GitLog -Count 1
        $LastCommit.Summary
    }
    else
    {
        $MatchingCommits = Get-GitLog
        @($MatchingCommits.Summary) -like "*$wordToComplete*"
    }
    $Completions -replace '"', '`"' -replace '\$', '`$' -replace '^|$', '"'     # escape dbl-quotes, wrap in dbl-quotes
}
