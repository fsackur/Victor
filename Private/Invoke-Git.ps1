using namespace System.Management.Automation

function Invoke-Git
{
    $Invocation = "git $($args)"
    $Invocation | Write-Verbose

    $Git = Get-Command git -CommandType Application

    $Output = & $Git @args *>&1

    if ($LASTEXITCODE)
    {
        $Output = $Output | Out-String
        $Output = $Output -replace '^[\s\r\n]*\n' -replace '\r?\n[\s\r\n]*$'

        $ErrorRecord = [Management.Automation.ErrorRecord]::new(
            [Management.Automation.RuntimeException]::new($Output),
            'NativeCommandError',
            'FromStdErr',
            "$($Git.Path) $($_args -join ' ')"
        )
        Write-Error -ErrorRecord $ErrorRecord
    }
    else
    {
        # ErrorRecords with empty Message cast to string as typename...
        [string[]]$Output -replace '^System\.Management\.Automation\.RemoteException$'
    }
}
Set-Alias git Invoke-Git
