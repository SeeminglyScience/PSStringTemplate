---
Module Name: PSStringTemplate
Module Guid: f188d0cf-291f-41a1-ae0e-c770d980cf6e
Download Help Link: {{Please enter FwLink manually}}
Help Version: 1.0.0.5
Locale: en-US
---

# PSStringTemplate Module

## Description

Create and render templates using the StringTemplate template engine.

## PSStringTemplate Cmdlets

### [Invoke-StringTemplate](Invoke-StringTemplate.md)

This cmdlet will take a Template object from a TemplateGroup, add specified parameters and
render the template into a string. It can use an existing Template object (from the
New-StringTemplateGroup cmdlet) or it can create a new Template using a string specified in
the "Definition" parameter.

### [New-StringTemplateGroup](New-StringTemplateGroup.md)

The New-StringTemplateGroup cmdlet allows you to create a group of
templates using the group definition syntax.  Templates within a group
can reference other templates in the same group.

You can use this to enumerate arrays, call different templates based on
conditions, or just for better organization.
