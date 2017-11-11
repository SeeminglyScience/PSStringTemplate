---
external help file: PSStringTemplate.dll-Help.xml
online version: https://github.com/SeeminglyScience/PSStringTemplate/blob/master/docs/en-US/New-StringTemplateGroup.md
schema: 2.0.0
---

# New-StringTemplateGroup

## SYNOPSIS

Define a group of templates.

## SYNTAX

```powershell
New-StringTemplateGroup -Definition <String>
```

## DESCRIPTION

The New-StringTemplateGroup cmdlet allows you to create a group of
templates using the group definition syntax.  Templates within a group
can reference other templates in the same group.

You can use this to enumerate arrays, call different templates based on
conditions, or just for better organization.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
PS> $group = New-StringTemplateGroup -Definition @'

    memberTemplate(Name, Parameters, ReturnType) ::= <<
<Name><if(ReturnType)>(<Parameters:paramTemplate(); separator=", ">)<endif>
>>

    paramTemplate(param) ::= "$<param.Name>"
'@
PS> $group | Invoke-StringTemplate -Name memberTemplate ([string].GetProperty('Length'))
Length
PS> $group | Invoke-StringTemplate -Name memberTemplate ([string].GetMethod('Clone'))
Clone()
PS> $group | Invoke-StringTemplate -Name memberTemplate ([string].GetMethod('IsNullOrWhiteSpace'))
IsNullOrWhiteSpace($value)
PS> $group | Invoke-StringTemplate -Name memberTemplate ([string].GetMethod('Insert'))
Insert($startIndex, $value)
```

Create a template to generate different member expressions from MemberInfo objects.

## PARAMETERS

### -Definition

The group definition string to use to compile a template group.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None

## OUTPUTS

### PSStringTemplate.TemplateGroupInfo

The compiled template group is returned to the pipeline. This can then be passed to
the Invoke-StringTemplate cmdlet for rendering.

## NOTES

## RELATED LINKS
