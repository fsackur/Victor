using namespace System.Management.Automation

function Invoke-Git
{
    "git $($args)" | Write-Verbose

    $Git = Get-Command git -CommandType Application

    $Output = & $Git @args *>&1

    if ($LASTEXITCODE)
    {
        $Output = $Output | Out-String
        $Output = $Output -replace '^[\s\r\n]*\n' -replace '\r?\n[\s\r\n]*$'
        $Output | Write-Error
    }
    else
    {
        $Output
    }
}
Set-Alias git Invoke-Git
