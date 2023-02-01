using namespace System.Management.Automation

function Invoke-Git
{
    $Invocation = "git $($args)"
    $Invocation | Write-Verbose

    $Git = Get-Command git -CommandType Application

    $Process = [Diagnostics.Process]::new()
    $Start = $Process.StartInfo
    $Start.CreateNoWindow = $true
    $Start.FileName = $Git.Path
    $Start.Arguments = $Invocation -replace '^git '
    # $Start.UseShellExecute = $false
    # $Start.RedirectStandardInput = $true
    # $Start.RedirectStandardOutput = $true
    # $Start.RedirectStandardError = $true

    $OutEvent = Register-ObjectEvent -Action {
        Write-Output $Event.SourceEventArgs.Data
    } -InputObject $Process -EventName OutputDataReceived

    $ErrEvent = Register-ObjectEvent -Action {
        Write-Output $Event.SourceEventArgs.Data
    } -InputObject $Process -EventName ErrorDataReceived

    try
    {
        [void]$Process.Start()
        while (-not $Process.HasExited)
        {
            Start-Sleep -Milliseconds 50
        }
    }
    finally
    {
        Unregister-Event -SourceIdentifier $OutEvent.Name
        Unregister-Event -SourceIdentifier $ErrEvent.Name
    }

    $HadError = [bool]$Process.ExitCode

    # ErrorRecords with empty Message cast to string as typename...
    [string[]]$Output = $Output -replace '^System\.Management\.Automation\.RemoteException$'

    if (-not $HadError)
    {
        return
        # return $Output.PSObject.BaseObject
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
