using namespace System.Management.Automation

function Invoke-Git
{
    $Invocation = "git $($args)"
    $Invocation | Write-Verbose

    $Git = Get-Command git -CommandType Application

    $Output = & $Git @args *>&1

    $HadError = [bool]$LASTEXITCODE

    # ErrorRecords with empty Message cast to string as typename...
    [string[]]$Output = $Output -replace '^System\.Management\.Automation\.RemoteException$'

    if (-not $HadError)
    {
        return $Output.PSObject.BaseObject
    }

    $Output = $Output | Out-String
    $Output = $Output -replace '^[\s\r\n]*\n' -replace '\r?\n[\s\r\n]*$'

    $ErrorRecord = [ErrorRecord]::new(
        [RuntimeException]::new($Output),
        'NativeCommandError',
        'FromStdErr',
        "$($Git.Path) $($_args -join ' ')"
    )

    $StackTraceField = [ErrorRecord].GetField('_scriptStackTrace', 'Instance,NonPublic')
    $StackTraceField.SetValue($ErrorRecord, 'foo')
    Write-Error -ErrorRecord $ErrorRecord
}
Set-Alias git Invoke-Git
