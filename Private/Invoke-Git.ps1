function Invoke-Git
{
    "git $($args)" | Write-Verbose

    $Git = Get-Command git -CommandType Application

    $Output = & $Git @args *>&1

    if ($?)
    {
        $Output | Write-Output
    }
    else
    {
        $Output | Write-Error
    }
}
Set-Alias git Invoke-Git
