using namespace System.Collections.Generic
using namespace System.Management.Automation

function Invoke-GitRebase
{
    <#
        .SYNOPSIS
        Performs a rebase.

        .DESCRIPTION
        You can rebase one branch onto another, or you can rebase a single branch to rewrite
        history.

        A git rebase takes commits, starting from a particular commit, and replays them with some
        change. Broadly-speaking, there are two use cases:

        - rebasing onto another branch, e.g. staging, so that your feature branch is up-to-date with
        upstream changes
        - rebasing interactively, so that you can clean up your commit history

        They are not strictly exclusive.

        This command runs git rebase with the --autostash parameter; any uncommitted changes will
        be stashed at the start of the rebase and re-applied at the end.

        This command also uses --autosquash option; any commits with messages beginning with
        'fixup!' or 'squash!' will be moved to the matching commit in the history and squashed into
        that commit. This is skipped if no matching commit is found.

        .PARAMETER Count
        Specify the number of commits to include in the rebase.

        .PARAMETER Onto
        Specify a branch or commit reference onto which to rebase.

        .PARAMETER FromRef
        Specify the starting commit for the rebase. This is exclusive - the commit provided will not
        be touched. Only the commits after the specified commit will be included in the rebase.

        .PARAMETER Interactive
        Specifies to perform an interactive rebase. This command may return before the rebase is
        complete; the user may need to run git commands to complete the rebase. Help will be shown
        in the terminal.

        .PARAMETER NoAutosquash
        Specifies that an interactive rebase should not automatically perform squashes and fixups.

        .PARAMETER Abort
        Aborts an interactive rebase that has paused at an intermediate point.

        .PARAMETER Continue
        Continues an interactive rebase that has paused at an intermediate point.

        .PARAMETER Skip
        Skips the current commit in an interactive rebase that has paused at an intermediate point.

        .OUTPUTS
        [psobject]

        .EXAMPLE
        rebase staging

        rebase: moved from 3ed185d to 0eb7f36
         CHANGELOG.md             |   4 +
         GitShell.psd1            |   2 +-
         Jenkinsfile (gone)       | 749 -----------------------------------------------
         Public/New-GitBranch.ps1 |   5 +
         Public/New-GitRepo.ps1   |   6 +-
         docs/README.md           |   4 +-
         6 files changed, 17 insertions(+), 753 deletions(-)

        Rebases commits since the last merge onto the staging branch. Outputs a summary of the diff
        between the old and new heads.

        If this rebase does not complete successfully, it will abort and return to the original
        state.

        .EXAMPLE
        rebase staging -Interactive

        Created autostash: 72c6252
        error: could not apply 5d99581... Version bump
        Resolve all conflicts manually, mark them as resolved with
        "git add/rm <conflicted_files>", then run "git rebase --continue".
        You can instead skip this commit: run "git rebase --skip".
        To abort and get back to the state before "git rebase", run "git rebase --abort".
        Could not apply 5d99581... Version bump
        Auto-merging GitShell.psd1
        CONFLICT (content): Merge conflict in GitShell.psd1
        Auto-merging CHANGELOG.md
        CONFLICT (content): Merge conflict in CHANGELOG.md

        # Edit GitShell.psd1 and CHANGELOG.md to resolve the conflicts
        > git add *
        > rebase -Continue

        [detached HEAD dd33e45] Version bump
         2 files changed, 27 insertions(+), 1 deletion(-)
        rebase: moved from 5d99581 to dd33e45
         CHANGELOG.md             |   4 +
         GitShell.psd1            |   4 -
         Jenkinsfile (gone)       | 749 -----------------------------------------------
         Public/New-GitBranch.ps1 |   5 +
         Public/New-GitRepo.ps1   |   6 +-
         docs/README.md           |   4 +-
         6 files changed, 16 insertions(+), 756 deletions(-)
        Applied autostash.
        Successfully rebased and updated refs/heads/4165-rebasing.

        Opens the Gitlens extension in VS Code to interactively order and amend the git history,
        before rebasing onto staging.

        In this example, a merge conflict was introduced in the GitShell.psd1 and CHANGELOG.md
        files. The command dropped to the terminal. We had to manually edit those files to resolve
        the conflicts. Then we ran `git add *` and `git rebase --continue` to complete the rebase.

        On success, outputs a summary of the diff between the old and new heads.

        .EXAMPLE
        > ggl 8

        Id      Author         UpdatedAt      Summary
        --      ------         ---------      -------
        3d42d52 Freddie Sackur 6 minutes ago  fixup! Summary after successful interactive rebase
        aa505ef Freddie Sackur 7 minutes ago  fixup! Don't output to Info stream on calls within the module
        8784987 Freddie Sackur 11 minutes ago Updated help
        ba8fb23 Freddie Sackur 12 minutes ago Summary after successful interactive rebase
        45c7c99 Freddie Sackur 2 hours ago    Add Undo-Git
        973e46c Freddie Sackur 3 hours ago    Added deprecation warning to Untracked
        1d70004 Freddie Sackur 3 hours ago    Tidy
        927400e Freddie Sackur 5 hours ago    Don't output to Info stream on calls within the module

        > rebase 8

        rebase: moved from 3d42d52 to 3680238
        Successfully rebased and updated refs/heads/4165-rebasing.

        > ggl 6

        Id      Author         UpdatedAt      Summary
        --      ------         ---------      -------
        3680238 Freddie Sackur 11 minutes ago Updated help
        273dc05 Freddie Sackur 12 minutes ago Summary after successful interactive rebase
        b7f1385 Freddie Sackur 2 hours ago    Add Undo-Git
        238f6b6 Freddie Sackur 3 hours ago    Added deprecation warning to Untracked
        55e185e Freddie Sackur 3 hours ago    Tidy
        f79de78 Freddie Sackur 5 hours ago    Don't output to Info stream on calls within the module

        Performs a non-interactive autosquash rebase. Before the rebase, there are two commits with
        a 'fixup!' prefix, corresponding to two older commits in the history. After the rebase,
        these fixup commits have been squashed into the older commits.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Count')]
    param ()

    dynamicparam
    {
        $DynParams = [RuntimeDefinedParameterDictionary]::new()

        if (-not $Script:RebaseParams)
        {
            function _rebase
            {
                param
                (
                    #region params for active rebase
                    [Parameter(ParameterSetName = 'Continue', Mandatory)]
                    [switch]$Continue,

                    [Parameter(ParameterSetName = 'Abort', Mandatory)]
                    [switch]$Abort,

                    [Parameter(ParameterSetName = 'Skip', Mandatory)]
                    [switch]$Skip,
                    #endregion params for active rebase

                    #region params for starting a rebase
                    [Parameter(ParameterSetName = 'Count', Position = 0)]
                    [ValidateRange(1, 5000)]
                    [int]$Count,

                    [Parameter(ParameterSetName = 'FromRef', Position = 0)]
                    [Parameter(ParameterSetName = 'Count')]
                    [string]$Onto,

                    [Parameter(ParameterSetName = 'FromRef')]
                    [string]$FromRef,

                    [Parameter()]
                    [switch]$Interactive,

                    [Parameter()]
                    [switch]$NoAutosquash
                    #endregion params for starting a rebase
                )
            }

            $Script:RebaseParams = (Get-Command _rebase).Parameters.Values | Write-Output
        }


        $Params = if (Test-ActiveRebase) {$Script:RebaseParams[0..2]} else {$Script:RebaseParams[3..7]}
        foreach ($Param in $Params)
        {
            $DynParam = [RuntimeDefinedParameter]::new(
                $Param.Name,
                $Param.ParameterType,
                $Param.Attributes
            )
            $DynParams.Add($DynParam.Name, $DynParam)
        }

        return $DynParams
    }

    end
    {
        $PSBoundParameters.GetEnumerator() | ForEach-Object {Set-Variable $_.Key $_.Value}

        if ($PSCmdlet.ParameterSetName -in ('Abort', 'Continue', 'Skip'))
        {
            try
            {
                $_editor = $env:GIT_EDITOR
                $env:GIT_EDITOR = 'true'        # short-circuits git's editor, so --continue doesn't prompt
                return git rebase --$($PSCmdlet.ParameterSetName.ToLower())
            }
            finally
            {
                $env:GIT_EDITOR = $_editor
            }
        }


        $RebaseArgs = @(
            "rebase",
            "-i",               # Always operate in interactive mode, to apply autosquash - we hack it with GIT_SEQUENCE_EDITOR
            "--autostash"
        )

        if (-not ($Interactive -and $NoAutosquash))
        {
            $RebaseArgs += "--autosquash"
        }

        if ($Onto)
        {
            $RebaseArgs += "--onto"
            $RebaseArgs += $Onto
        }

        if (-not $FromRef)
        {
            if ($Count)
            {
                $FromRef = "HEAD~$Count"
            }
            else
            {
                $FromRef = Get-GitLog -SinceLastMerge | Select-Object -Last 1 -ExpandProperty Id
                if (-not $FromRef)
                {
                    throw "Unable to determine the last merge in the commit history to use as a rebase base. Try specifying FromRef or Count."
                }
                $FromRef = "$FromRef^1"
            }
        }
        $RebaseArgs += $FromRef


        if ($Interactive)
        {
            return git $RebaseArgs
        }


        try
        {
            $Output = $null

            $_gse = $env:GIT_SEQUENCE_EDITOR
            $env:GIT_SEQUENCE_EDITOR = "true"   # short-circuits git's todo editor, but not the primary editor

            $Output = git $RebaseArgs 2>&1

            if ($LASTEXITCODE)
            {
                throw $LASTEXITCODE
            }
        }

        catch
        {
            $Escape    = [char]27
            $Firebrick = "$Escape[38;2;178;34;34m"
            $Reset     = "$Escape[0m"
            @($Output) -match '^CONFLICT' | ForEach-Object {Write-Information "$Firebrick$_$Reset" -InformationAction Continue}
            $Output | Select-Object -Last 1 | Write-Error

            git rebase --abort
        }

        finally
        {
            $env:GIT_SEQUENCE_EDITOR = $_gse
        }
    }
}


Register-ArgumentCompleter -CommandName Invoke-GitRebase -ParameterName Onto -ScriptBlock {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    [string[]]$BranchNames = Get-GitBranch | Where-Object Active -ne $true | Select-Object -ExpandProperty Name

    ($BranchNames -like "$wordToComplete*"), ($BranchNames -like "*?$wordToComplete*") | Write-Output
}
