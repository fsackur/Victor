Describe Get-GitLog {

    BeforeAll {
        Remove-Module Victor -ErrorAction SilentlyContinue
        $Module = $PSScriptRoot |
            Split-Path |
            Join-Path -ChildPath Victor.psd1 |
            Import-Module -PassThru -ErrorAction Stop


        $TestPath = ($env:TEMP | Resolve-Path -ErrorAction SilentlyContinue), '/tmp' |
            Select-Object -First 1 |
            Join-Path -ChildPath 'Victor.Tests'
        $TestPath = New-Item $TestPath -ItemType Directory -Force -ErrorAction Stop

        $TestRepos = $PSScriptRoot |
            Join-Path -ChildPath 'Data' |
            Get-ChildItem -Filter 'repo*.zip' -PipelineVariable Path |
            ForEach-Object {
                $Destination = Join-Path $TestPath $_.BaseName
                Expand-Archive $_.FullName $Destination -ErrorAction SilentlyContinue
                Get-Item $Destination
            }

        Push-Location $TestRepos[0]
    }

    AfterAll {
        Pop-Location
    }

    It "Gets commits" {
        (Get-GitLog).Count | Should -Be 6
    }
}
