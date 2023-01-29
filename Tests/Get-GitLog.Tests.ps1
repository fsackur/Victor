
BeforeAll {. (Join-Path $PSScriptRoot Test.Setup.ps1)}


Describe Get-GitLog {

    BeforeAll {
        New-TestGitDir | Push-Location

        $ExpectedCommitCount = 3
        1..$ExpectedCommitCount |
            ForEach-Object {
                git commit -m "Test commit $_" --allow-empty *>&1 | Write-Debug
            }
    }

    AfterAll {
        Pop-Location
        Clear-TestGitDir
    }

    It "Gets commits" {
        (Get-GitLog).Count | Should -Be $ExpectedCommitCount
    }

    It "Gets up to Count commits" {
        (Get-GitLog -Count 9).Count | Should -Be $ExpectedCommitCount
        (Get-GitLog -Count 2).Count | Should -Be 2
    }
}
