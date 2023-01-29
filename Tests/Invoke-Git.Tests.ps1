
BeforeDiscovery {
    . (Join-Path $PSScriptRoot Test.Setup.ps1)
}


InModuleScope Victor {

    Describe Invoke-Git {

        BeforeAll {
            $Global:__VICTOR_TEST_CAPTURED_GIT_ARGS = $null
            function Mock-Git {
                $Global:__VICTOR_TEST_CAPTURED_GIT_ARGS = $args

                if ($StdOut) {$StdOut}
                if ($StdErr) {$StdErr | Write-Error}
            }

            Mock Get-Command -ParameterFilter {$Name -eq 'git' -and $CommandType -eq 'Application'} {
                Get-Item Function:\Mock-Git
            }

            Mock Write-Verbose {}
        }

        AfterAll {
            Remove-Variable -Scope Global __VICTOR_TEST_CAPTURED_GIT_ARGS -ErrorAction SilentlyContinue
        }


        Context "<_.Name>" -Foreach @(
            @{
                Name    = 'Success'
                GitArgs = 'log', '-n', '3', '--pretty=oneline'
                StdOut  = '2345678 Commit 3', '1234567 Commit 2', '0123456 Commit 1'
                StdErr  = $null
            },
            @{
                Name    = 'Error'
                GitArgs = 'checkout', 'some_nonexistent_branch'
                StdOut  = $null
                StdErr  = 'pathspec ''some_nonexistent_branch'' did not match any file(s) known to git'
            }
        ) {

            BeforeAll {
                try
                {
                    $ErrorActionPreference = 'Stop'
                    $ActualOutput = Invoke-Expression "git $GitArgs"
                }
                catch
                {
                    $ActualError = $_
                }
            }

            It "Calls git" {
                $Global:__VICTOR_TEST_CAPTURED_GIT_ARGS | Should -Be $GitArgs
            }

            It "Echoes args to verbose stream" {
                Should -Invoke Write-Verbose -Scope Context -Times 1 -Exactly -ParameterFilter {
                    $Message -eq "git $GitArgs"
                }
            }

            It "$(if ($StdOut) {'Writes'} else {'Does not write'}) output" {
                $ActualOutput | Should -Be $StdOut
            }

            It "$(if ($StdErr) {'Writes'} else {'Does not write'}) error" {
                $ActualError | Should -Be $StdErr
            }
        }
    }
}
