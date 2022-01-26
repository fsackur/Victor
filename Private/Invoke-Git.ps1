using namespace System.Management.Automation

function Invoke-Git
{
    "git $($args)" | Write-Verbose

    $Git = Get-Command git -CommandType Application

    $Output = & $Git @args *>&1

    if ($LASTEXITCODE)
    {
        $Output = $Output |
            ForEach-Object {if ($_ -is [ErrorRecord]) {Write-Error -ErrorRecord $_} else {$_}} |
            Out-String

        $Output -replace '^[\s\r\n]*\n' -replace '\r?\n[\s\r\n]*$' | Write-Error
    }
    else
    {
        $Output = $Output | Out-String
        $Output -replace '^[\s\r\n]*\n' -replace '\r?\n[\s\r\n]*$'
    }
}
Set-Alias git Invoke-Git
