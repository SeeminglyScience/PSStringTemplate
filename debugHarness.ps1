# Use this file to debug the module.
Import-Module -Name $PSScriptRoot\Release\PSStringTemplate\*\PSStringTemplate.psd1 -Force

Invoke-StringTemplate -Definition '<Name>' @{Name = 'Test'}