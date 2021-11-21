function Get-GitConfiguration
{
    <#
        .SYNOPSIS
        Gets git config.

        .DESCRIPTION
        Git configuration exists in several files ('scopes'). The precedence is:

        - System: per-machine configuration
        - Global: usually located in the user's home folder
        - Local: configuration within a repo, affecting only that repo
        - Worktree: only relevant when using git worktrees

        By default, this command will get the effective configuration.

        .PARAMETER Name
        Specify the name of a config element to get only the effective configured value.

        .PARAMETER Scope
        Get only the config elements from the specified scope.

        .PARAMETER AsList
        Get all config elements, whether overridden or not, as a list.

        .OUTPUTS
        [psobject]

        .EXAMPLE
        > Get-GitConfiguration

        core.autocrlf         : 0
        core.bare             : false
        core.editor           : code --wait
        core.filemode         : false
        core.fscache          : true
        core.ignorecase       : true
        core.logallrefupdates : true

        Gets the effective git config.

        .EXAMPLE
        > Get-GitConfiguration core.editor

        code --wait

        Gets the effective git config for the core.editor config element.

        .EXAMPLE
        > Get-GitConfiguration -AsList

        Name                  Value       Scope
        ----                  -----       -----
        core.autocrlf         0           global
        core.autocrlf         true        system
        core.bare             false       local
        core.editor           code --wait global
        core.filemode         false       local
        core.fscache          true        system
        core.ignorecase       true        local
        core.logallrefupdates true        local

        Gets all configuration elements, including those overridden by elements in higher-precedence
        scopes.
    #>

    [OutputType([string], ParameterSetName = 'ByName')]
    [OutputType([psobject], ParameterSetName = 'Default')]
    [OutputType([psobject[]], ParameterSetName = 'AsList')]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param
    (
        [Parameter(ParameterSetName = 'ByName', Mandatory, Position = 0)]
        [string]$Name,

        [Parameter()]
        [ValidateSet('System', 'Global', 'Local', 'Worktree')]
        [string]$Scope,

        [Parameter(ParameterSetName = 'AsList')]
        [switch]$AsList
    )


    $AllScopes = $MyInvocation.MyCommand.Parameters.Scope.Attributes.ValidValues


    $ConfigArgs = @('config')

    if ($Scope)
    {
        $ConfigArgs += "--$Scope".ToLower()
    }


    if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        $ConfigArgs += '--get'
        $ConfigArgs += $Name

        return git $ConfigArgs
    }


    $ConfigArgs += '--show-scope'
    $ConfigArgs += '--list'


    $ConfigText = git $ConfigArgs


    $ConfigItems = [Collections.Generic.List[psobject]]::new()
    $TextInfo = (Get-Culture).TextInfo
    foreach ($Line in $ConfigText)
    {
        $_Scope, $KvpText = $Line -split '\s+', 2

        # Ignore per-repo config that holds current branches and remotes
        if ($_Scope -eq 'local' -and $KvpText -match '^(branch|remote)')
        {
            continue
        }

        $Key, $Value = $KvpText -split '=', 2
        $ConfigItems.Add([pscustomobject]@{
            Name  = $Key
            Value = $Value
            Scope = $TextInfo.ToTitleCase($_Scope)
        })
    }

    # Sort in order of precedence; lower items override higher ones of the same name
    $ConfigItems = $ConfigItems | Sort-Object Name, {$AllScopes.IndexOf($_.Scope)}


    if ($PSCmdlet.ParameterSetName -eq 'AsList')
    {
        return $ConfigItems
    }


    $Output = [ordered]@{}
    $ConfigItems | ForEach-Object {$Output[$_.Name] = $_.Value}

    [pscustomobject]$Output
}
