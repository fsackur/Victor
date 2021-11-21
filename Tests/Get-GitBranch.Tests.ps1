
BeforeAll {. (Join-Path $PSScriptRoot Test.Setup.ps1)}


Describe Get-GitBranch {

    BeforeAll {

        # upstream fork has main and staging branches
        $Upstream = New-TestGitDir
        $Upstream | Push-Location
        1..3 | ForEach-Object {git commit -m "Test commit $_" --allow-empty *>&1 | Write-Debug}
        git checkout -b staging *>&1 | Write-Debug
        Pop-Location

        # origin fork has feature branch
        $Origin = New-TestGitDir -CloneFrom $Upstream
        $Origin | Push-Location
        git checkout -b feature *>&1 | Write-Debug
        4, 5 | ForEach-Object {git commit -m "Test commit $_" --allow-empty *>&1 | Write-Debug}
        Pop-Location

        # local clone has dev branch
        New-TestGitDir -CloneFrom $Origin | Push-Location
        git remote add upstream $Upstream       *>&1 | Write-Debug
        git fetch upstream                      *>&1 | Write-Debug
        git checkout --track upstream/main      *>&1 | Write-Debug
        git checkout --track upstream/staging   *>&1 | Write-Debug
        git checkout --track origin/feature     *>&1 | Write-Debug
        git checkout -b dev                     *>&1 | Write-Debug
    }

    AfterAll {
        Pop-Location
        Clear-TestGitDir
    }

    Context "<_.Name>" -Foreach @(
        @{
            Name           = 'Active branch'
            Params         = @{Active = $true}
            ExpectedRemote = @()
            ExpectedActive = 'dev'
        },
        @{
            Name           = 'All branches'
            Params         = @{}
            ExpectedRemote = 'upstream/main', 'upstream/staging', 'origin/feature'
            ExpectedActive = 'dev'
        }
    ) {

        BeforeAll {
            $BranchNames = Get-GitBranch @Params -NameOnly
            $Branches    = Get-GitBranch @Params

            $ExpectedBranchNames = ($ExpectedRemote -replace '.*/') + $ExpectedActive
        }

        It "Gets branch name$(if (-not $Params.Active) {'s'})" {
            $BranchNames | Sort-Object | Should -Be ($ExpectedBranchNames | Sort-Object)
        }

        It "Gets branch$(if (-not $Params.Active) {'es'})" {
            $Branches.Count | Should -Be $ExpectedBranchNames.Count
            $Branches.Name | Sort-Object | Should -Be ($ExpectedBranchNames | Sort-Object)
        }

        It "Finds active branch" {
            $Branches | Where-Object {$_.Active} | Select-Object -ExpandProperty Name | Should -Be $ExpectedActive
        }

        It "Gets tracking branch" {
            $Branches.Upstream | Where-Object {$_} | Sort-Object | Should -Be ($ExpectedRemote | Sort-Object)
        }

        It "Gets SHA" {
            @($Branches.Id) | Should -Match '^[0-9a-f]{7,}$'
        }
    }
}
