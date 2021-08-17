Describe Get-GitLog {

    BeforeAll {
        Remove-Module Victor -ErrorAction SilentlyContinue
        $Module = $PSScriptRoot |
            Split-Path |
            Join-Path -ChildPath Victor.psd1 |
            Import-Module -PassThru -ErrorAction Stop

        Push-Location $Module.ModuleBase
    }

    AfterAll {
        Pop-Location
    }

    It "Gets commits" {
        (Get-GitLog).Count | Should -BeGreaterThan 2
    }
}
