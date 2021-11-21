function Update-GitCommit
{
    <#
        .SYNOPSIS
        Amends an existing commit. Aliased to `amend`.

        .DESCRIPTION
        By default, this command will update the last commit using git commit --amend.

        You can also provide the commit message of an existing commit to be amended. This command
        will, by default, immediately rewrite the git history to apply the change to the specified
        commit.

        > Note that this may also apply other fixups and squashes that have not yet been squashed.

        If there are changed files already in the index, this command will commit only those files.
        Otherwise, all changed files in the working tree are added and committed.

        See [About Rewriting History](https://pages.github.rackspace.com/windows-automation/GitShell/about_using_gitshell_like_a_boss).

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

        .EXAMPLE
        amend

        WARNING: Nothing in index; auto-staging all files
        amend: moved from e52dc9b to dfd9fea
         test (new) | 1 +
         1 file changed, 1 insertion(+)

        Add uncommitted changes to the previous commit.

        .EXAMPLE
        amend "Updated help for Reset-GitBranch"

        WARNING: Nothing in index; auto-staging all files
        fixup: moved from dfd9fea to 6f8a0e9
         Public/Reset-GitBranch.ps1 | 7 ++++---
         1 file changed, 4 insertions(+), 3 deletions(-)

        rebase: moved from 6f8a0e9 to 79c41ff
        Successfully rebased and updated refs/heads/4165-rebasing.

        Amends the commit in the history that has the message "Updated help for Reset-GitBranch".

        .LINK
        https://pages.github.rackspace.com/windows-automation/GitShell/about_using_gitshell_like_a_boss
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


    if (-not $PSBoundParameters.ContainsKey('InformationAction'))
    {
        $InformationPreference = 'Continue'
    }


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
        $_whitespace = Get-GitConfiguration apply.whitespace -Scope Local
        Set-GitConfiguration apply.whitespace nowarn -Scope Local
        git stash --all | Out-Null

        git commit --amend --no-edit -m $EscapedMessage | Out-Null

        git stash pop --index | Out-Null
        Set-GitConfiguration apply.whitespace $_whitespace -Scope Local
    }
    else
    {
        $OrigHead = (git rev-parse HEAD) -replace '(?<=^.{7}).*'
        git commit -m "fixup! $EscapedMessage" | Out-Null

        Show-GitActionSummary fixup -Commits $OrigHead, $NewHead
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
