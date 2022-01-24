@{
    Description          = 'A little helper for git history.'
    ModuleVersion        = '0.0.1'
    HelpInfoURI          = 'https://pages.github.com/fsackur/Victor'

    GUID                 = 'ac597611-e9a1-40d4-8282-9ecc14b6c789'

    Author               = 'Freddie Sackur'
    CompanyName          = 'DustyFox'
    Copyright            = '(c) 2021 Freddie Sackur. All rights reserved.'

    RootModule           = 'Victor.psm1'

    AliasesToExport      = @(
        'a',
        'amend',
        'c',
        'ggl',
        'rebase',
        'rst'
    )

    FunctionsToExport    = @(
        'Add-GitFile',
        'Get-GitBranch',
        'Get-GitLog',
        'Get-GitStatus',
        'Reset-Git',
        'Invoke-GitRebase',
        'Update-GitCommit',
        'Write-GitCommit'
    )

    PrivateData          = @{
        PSData = @{
            LicenseUri = 'https://raw.githubusercontent.com/fsackur/Victor/main/LICENSE'
            ProjectUri = 'https://github.com/fsackur/Victor'
            Tags       = @(
                'Amend',
                'Rebase',
                'Reword',
                'Rewrite',
                'Git',
                'Commit',
                'History'
            )
        }
    }
}
