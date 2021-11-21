function Set-GitConfiguration
{
    <#
        .SYNOPSIS
        Sets a git config element.

        .DESCRIPTION
        Git configuration exists in several files ('scopes'). The precedence is:

        - System: per-machine configuration
        - Global: usually located in the user's home folder
        - Local: configuration within a repo, affecting only that repo
        - Worktree: only relevant when using git worktrees

        By default, this command will set config elements at the Global scope.

        .PARAMETER Name
        Specify the name of the config element to set.

        .PARAMETER Value
        Specify the value of the config element to set. Null or an empty string will cause the
        element to be deleted from the config for the scope.

        .PARAMETER Scope
        Specify the scope in which to set config. Defaults to 'Global'.

        .OUTPUTS
        [void]

        .EXAMPLE
        Set-GitConfiguration core.autocrlf $null

        Unsets the core.autocrlf setting from the Global config.

        .EXAMPLE
        Set-GitConfiguration user.email funkmaster@githubparty.com -Scope Local

        Sets the committer email address for the current repository.
    #>

    [OutputType([void])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory, Position = 1)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter()]
        [ValidateSet('System', 'Global', 'Local', 'Worktree')]
        [string]$Scope = 'Global'
    )


    $ConfigArgs = @(
        'config'
    )

    if ($Scope)
    {
        $ConfigArgs += "--$Scope".ToLower()
    }

    if ($Value)
    {
        $ConfigArgs += $Name
        $ConfigArgs += "$Value"
    }
    else
    {
        $ConfigArgs += '--unset'
        $ConfigArgs += $Name
    }


    return git $ConfigArgs
}
