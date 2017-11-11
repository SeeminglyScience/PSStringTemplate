Describe 'Manifest Validation' {
    $script:manifestPath = Resolve-Path "$PSScriptRoot\..\Release\PSStringTemplate\*\PSStringTemplate.psd1"
    It 'Passes Test-ModuleManifest' {
        $script:manifest = Test-ModuleManifest -Path $script:manifestPath -WarningAction 0
    }
    It 'Has the correct properties' {
        $manifest = $script:manifest
        $manifest.Name              | Should -Be 'PSStringTemplate'
        $manifest.Guid              | Should -Be 'f188d0cf-291f-41a1-ae0e-c770d980cf6e'
        $manifest.RootModule        | Should -Be '.\PSStringTemplate.psm1'
        $manifest.PowerShellVersion | Should -Be '3.0'
        $manifest.DotNetFrameworkVersion | Should -Be '4.5'
    }
}

if (-not (Get-Module PSStringTemplate -ea 0)) {
    Import-Module $PSScriptRoot\..\Release\PSStringTemplate\*\PSStringTemplate.psd1 -Force
}

Describe 'Readme examples work as is' {
    It 'Anonymous template with dictionary parameters' {
        Invoke-StringTemplate -Definition '<language> is very <adjective>!' -Parameters @{
            language = 'PowerShell'
            adjective = 'cool'
        } | Should -Be 'PowerShell is very cool!'
    }
    It 'Anonymous template with object as parameters' {
        $definition = 'Name: <Name><\n>Commands: <ExportedCommands; separator=", ">'

        # Need to pick a different module as a example, one that is default with 3.0
        $result = Invoke-StringTemplate -Definition $definition -Parameters (Get-Module -ListAvailable PSReadLine)[0]

        # Can't directly compare because the commands come out in a different order.
        $result.StartsWith('Name: PSReadline') | Should -Be $true
        (Get-Module -ListAvailable PSReadline)[0].ExportedCommands | ForEach-Object { $result -match $_.ToString() }
    }
    It 'TemplateGroup definition' {
        $definition = @'
    Param(parameter) ::= "[<parameter.ParameterType.Name>] $<parameter.Name>"
    Method(member) ::= <<
[<member.ReturnType.Name>]<if(member.IsStatic)> static<endif> <member.Name> (<member.Parameters:Param(); separator=", ">) {
    throw [NotImplementedException]::new()
}
>>
    Class(Name, DeclaredMethods) ::= <<
class MyClass : <Name> {
    <DeclaredMethods:Method(); separator="\n\n">
}
>>
'@
        $group = New-StringTemplateGroup -Definition $definition
        $group | Invoke-StringTemplate -Name Class -Parameters ([System.Runtime.InteropServices.ICustomMarshaler]) |
            Should -Be 'class MyClass : ICustomMarshaler {
    [Object] MarshalNativeToManaged ([IntPtr] $pNativeData) {
        throw [NotImplementedException]::new()
    }

    [IntPtr] MarshalManagedToNative ([Object] $ManagedObj) {
        throw [NotImplementedException]::new()
    }

    [Void] CleanUpNativeData ([IntPtr] $pNativeData) {
        throw [NotImplementedException]::new()
    }

    [Void] CleanUpManagedData ([Object] $ManagedObj) {
        throw [NotImplementedException]::new()
    }

    [Int32] GetNativeDataSize () {
        throw [NotImplementedException]::new()
    }
}'
    }
    It 'New-StringTemplateGroup example' {
        $group = New-StringTemplateGroup -Definition @'

    memberTemplate(Name, Parameters, ReturnType) ::= <<
<Name><if(ReturnType)>(<Parameters:paramTemplate(); separator=", ">)<endif>
>>

    paramTemplate(param) ::= "$<param.Name>"
'@
        $group | Invoke-StringTemplate -Name memberTemplate ([string].GetProperty('Length')) |
            Should -Be 'Length'
        $group | Invoke-StringTemplate -Name memberTemplate ([string].GetMethod('Clone')) |
            Should -Be 'Clone()'
        $group | Invoke-StringTemplate -Name memberTemplate ([string].GetMethod('IsNullOrWhiteSpace')) |
            Should -Be 'IsNullOrWhiteSpace($value)'
        $group | Invoke-StringTemplate -Name memberTemplate ([string].GetMethod('Insert')) |
            Should -Be 'Insert($startIndex, $value)'
    }
}
