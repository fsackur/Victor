
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

        $ExpectedRemoteBranchNames   = 'upstream/main', 'upstream/staging', 'origin/feature'
        $ExpectedTrackingBranchNames = $ExpectedRemoteBranchNames -replace '.*/'
        $ExpectedBranchNames         = $ExpectedTrackingBranchNames + 'dev'
    }

    AfterAll {
        Pop-Location
        Clear-TestGitDir
    }

    It "Gets branches" {
        (Get-GitBranch).Count | Should -Be $ExpectedBranchNames.Count
    }
}
