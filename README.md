# PSStringTemplate

The PSStringTemplate module provides a PowerShell friendly interface for creating templates using the
[StringTemplate4](https://github.com/antlr/antlrcs) template engine.

## Examples

### Anonymous template with dictionary parameters

```powershell
Invoke-StringTemplate -Definition '<language> is very <adjective>!' -Parameters @{
    language = 'PowerShell'
    adjective = 'cool'
}
```

```txt
PowerShell is very cool!
```

### Anonymous template with object as parameters

```powershell
$definition = 'Name: <Name><\n>Commands: <ExportedCommands; separator=", ">'
Invoke-StringTemplate -Definition $definition -Parameters (Get-Module PSReadLine)
```

```txt
Name: PSReadline
Commands: Get-PSReadlineKeyHandler, Get-PSReadlineOption, Remove-PSReadlineKeyHandler, Set-PSReadlineKeyHandler, Set-PSReadlineOption, PSConsoleHostReadline
```

### TemplateGroup definition

```powershell
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
$group | Invoke-StringTemplate -Name Class -Parameters ([System.Runtime.InteropServices.ICustomMarshaler])
```

```txt
class MyClass : ICustomMarshaler {
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
}
```

For more details on the template definition syntax see the documentation for the [StringTemplate4 project](https://github.com/antlr/stringtemplate4/blob/master/doc/index.md).
