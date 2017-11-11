# PSStringTemplate

The PSStringTemplate module provides a PowerShell friendly interface for creating templates using the
[StringTemplate4](https://github.com/antlr/antlrcs) template engine.

This project adheres to the Contributor Covenant [code of conduct](https://github.com/SeeminglyScience/PSStringTemplate/tree/master/docs/CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code. Please report unacceptable behavior to seeminglyscience@gmail.com.

## Build Status

|AppVeyor (Windows)|CircleCI (Linux)|CodeCov|
|---|---|---|
|[![Build status](https://ci.appveyor.com/api/projects/status/3uvr9oq297uhvj8p?svg=true)](https://ci.appveyor.com/project/SeeminglyScience/psstringtemplate)|[[![CircleCI](https://circleci.com/gh/SeeminglyScience/PSStringTemplate.svg?style=svg)](https://circleci.com/gh/SeeminglyScience/PSStringTemplate)|[![codecov](https://codecov.io/gh/SeeminglyScience/PSStringTemplate/branch/master/graph/badge.svg)](https://codecov.io/gh/SeeminglyScience/PSStringTemplate)|

## Documentation

Check out our **[documentation](https://github.com/SeeminglyScience/PSStringTemplate/tree/master/docs/en-US/PSStringTemplate.md)** for information about how to use this project. For more details on the template definition syntax specifically see the documentation for the [StringTemplate4 project](https://github.com/antlr/stringtemplate4/blob/master/doc/index.md).

## Installation

### Gallery

```powershell
Install-Module PSStringTemplate -Scope CurrentUser
```

### Source

```powershell
git clone 'https://github.com/SeeminglyScience/PSStringTemplate.git'
Set-Location ./PSStringTemplate
Install-Module platyPS, Pester, InvokeBuild -Force
Import-Module platyPS, Pester, InvokeBuild
Invoke-Build -Task Install
```

## Usage

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

## Contributions Welcome!

We would love to incorporate community contributions into this project.  If you would like to
contribute code, documentation, tests, or bug reports, please read our [Contribution Guide](https://github.com/SeeminglyScience/ClassExplorer/tree/master/docs/CONTRIBUTING.md) to learn more.
