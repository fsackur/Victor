function Invoke-Git
{
    "git $($args)" | Write-Verbose

    $Git = Get-Command git -CommandType Application

    $Output = & $Git @args *>&1

    if ($LASTEXITCODE)
    {
        $Output | ForEach-Object {
            if ($_ -is [Management.Automation.ErrorRecord])
            {
                Write-Error -ErrorRecord $_
            }
            else
            {
                Write-Error -Message $_
            }
        }
    }
    else
    {
        $Output | ForEach-Object {[string]$_}
    }
}
Set-Alias git Invoke-Git
