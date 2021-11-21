$CallStack             = Get-PSCallStack
[bool]$IsInternalCall  = $CallStack[1].InvocationInfo.MyCommand.Module -eq $MyInvocation.MyCommand.Module
[bool]$IsTabCompleting = $CallStack.Command -match 'TabExpansion'
