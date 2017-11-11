---
external help file: PSStringTemplate.dll-Help.xml
online version: https://github.com/SeeminglyScience/PSStringTemplate/blob/master/docs/en-US/Invoke-StringTemplate.md
schema: 2.0.0
---

# Invoke-StringTemplate

## SYNOPSIS

Renders a Template object.

## SYNTAX

### ByDefinition

```powershell
Invoke-StringTemplate -Definition <String> [[-Parameters] <PSObject>]
```

### ByGroup

```powershell
Invoke-StringTemplate [-Group] <TemplateGroupInfo> [-Name <String>] [[-Parameters] <PSObject>]
```

## DESCRIPTION

This cmdlet will take a Template object from a TemplateGroup, add specified parameters and
render the template into a string. It can use an existing Template object (from the
New-StringTemplateGroup cmdlet) or it can create a new Template using a string specified in
the "Definition" parameter.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
PS> Invoke-StringTemplate -Definition '<language> is very <adjective>!' -Parameters @{
    language = 'PowerShell'
    adjective = 'cool'
}
```

```txt
Output
------

PowerShell is very cool!
```

### -------------------------- EXAMPLE 2 --------------------------

```powershell
PS> $definition = 'Name: <Name><\n>Commands: <ExportedCommands; separator=", ">'
PS> Invoke-StringTemplate -Definition $definition -Parameters (Get-Module PSReadLine)
```

```txt
Output
------

Name: PSReadline
Commands: Get-PSReadlineKeyHandler, Get-PSReadlineOption, Remove-PSReadlineKeyHandler, Set-PSReadlineKeyHandler, Set-PSReadlineOption, PSConsoleHostReadline
```

### -------------------------- EXAMPLE 3 --------------------------

```powershell
PS> $definition = @'
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
PS> $group = New-StringTemplateGroup -Definition $definition
PS> $group | Invoke-StringTemplate -Name Class -Parameters ([System.Runtime.InteropServices.ICustomMarshaler])
```

```txt
Output
------

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

## PARAMETERS

### -Definition

Specifies a Template definition string to create a new Template to be rendered.

```yaml
Type: String
Parameter Sets: ByDefinition
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Group

Specifies an existing TemplateGroup to retrieve a template from.

```yaml
Type: TemplateGroupInfo
Parameter Sets: ByGroup
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Name

Specifies the name of the Template within the TemplateGroup.

```yaml
Type: String
Parameter Sets: ByGroup
Aliases: Name

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Parameters

Specifies the arguments to pass to the template.  If a IDictionary object (such as a hashtable) is
specified, the entries will be used as arguments.  All other objects will use the objects properties
as arguments.

Some methods will also be added as arguments if they meet the following criteria:

- Has a return value
- Has a parameterless overload
- The name follows the format "GetSomething"
- Does not have a matching property with value

As an example, the method RuntimeMethodInfo.GetParameters() would be added as an argument with the name
"Parameters".  This is to stay consistent with StringTemplate4 behavior. See documentation for the
StringTemplate4 template engine more information.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### PSStringTemplate.TemplateGroupInfo

You can pass template groups from New-StringTemplateGroup to this cmdlet.  You can also pass objects with a property
named "Group".

### System.String

You can pass objects with a property named "Name" as template names to this cmdlet.


## OUTPUTS

### System.String

The rendered template will be returned as a string.

## NOTES

## RELATED LINKS
