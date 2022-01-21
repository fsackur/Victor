function Get-GitStatus
{
    <#
        .SYNOPSIS
        Returns git status information

        .DESCRIPTION
        Returns git status information in a structered object

        .PARAMETER Untracked
        Returns whether there are any uncommitted files in the repo.

        Note: this parameter is misleadingly-named. It does not measure untracked files.

        This parameter is deprecated and will emit a warning.

        .PARAMETER Reponame
        The name of the repo to work in

        Defaults to assuming we are the root of a module, like C:\Githubdata\GitShell

        .OUTPUTS
        [psobject[]]

        .EXAMPLE
        Get-GitStatus

        File                        Index    WorkingTree
        ----                        -----    -----------
        Public/Get-GitStatus.ps1    Modified
        Public/Update-GitCommit.ps1          Modified
        Private/void.txt                     Deleted
        Private/Get-GitDir.ps1               Untracked
        Public/test                          Untracked

        Get status of files in the current repo. In this example, 'Public/Get-GitStatus.ps1' is in
        the index, so will be committed in the next commit.
    #>

    [CmdletBinding()]
    param ()

    # https://git-scm.com/docs/git-status#_output
    $States = @{
        ' ' = ''    # 'Unmodified' - but we don't want to show that in the output
        'M' = 'Modified'
        'A' = 'Added'
        'D' = 'Deleted'
        'R' = 'Renamed'
        'C' = 'Copied'
        'U' = 'Updated but unmerged'
        '?' = 'Untracked'
    }

    $Pattern = (
        '^(?<index>.)' +        # Char for status of X column (see link) - usually, index
        '(?<working>.)\s*' +    # Char for status of Y column (see link) - usually, working tree (i.e. not added for commit)
        '(?<file>.*)'           # File path; for renames, may take form 'oldname -> newname'
    )

    $IsWindowsDirSep = [System.IO.Path]::DirectorySeparatorChar -eq '\'


    $Changes = git status -s | ForEach-Object {

        if ($_ -match $Pattern)
        {
            $Properties = [ordered]@{
                File        = $Matches.file
                Index       = $States[$Matches.index]
                WorkingTree = $States[$Matches.working]
            }

            # Untracked files shouldn't show a value under "Index"
            if ($_ -match '^\?\?')
            {
                $Properties.Index = $null
            }

            # Untracked files often show up just as a directory. Expand to include the actual files.
            if ($Properties.File -match '/$')
            {
                $Files = Get-ChildItem $Properties.File -Recurse -File | Resolve-Path -Relative

                # For consistency with git output, use linux separators
                if ($IsWindowsDirSep)
                {
                    $Files = $Files -replace '\\', '/'
                }

                $Files | ForEach-Object {
                    $Properties.File = $_ -replace '^./'
                    [pscustomobject]$Properties
                }
            }
            else
            {
                [pscustomobject]$Properties
            }
        }
        else
        {
            Write-Error "Failed to parse '$_'"
        }
    }

    $Changes |
        Sort-Object File |
        Sort-Object Index, WorkingTree -Descending
}
