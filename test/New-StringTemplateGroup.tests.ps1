if (-not (Get-Module PSStringTemplate -ea 0)) {
    Import-Module $PSScriptRoot\..\Release\PSStringTemplate\*\PSStringTemplate.psd1 -Force
}

Describe 'Template Group Tests' {
    It 'can create a basic group' {
        $result = New-StringTemplateGroup -Definition 'template() ::= "Template"'
        $result.Templates.Name | Should Be 'template'
    }
    It 'can create a group with attributes' {
        $result = New-StringTemplateGroup -Definition 'template(One, Two) ::= "<One>: <Two>"'
        $result.Templates.Name | Should Be 'template'
        $result.Templates.Parameters | Should Be 'One','Two'
    }
    It 'can create multiple templates' {
        $result = New-StringTemplateGroup -Definition '
            template1(One,Two) ::= "<One>: <Two>"
            template2(Three) ::= "<Three>"
        '
        $result.Templates.Name | Should Be 'template1','template2'
        $result.Templates.Parameters | Should Be 'One','Two','Three'
    }
    It 'can create multi-line templates' {
        $result = New-StringTemplateGroup -Definition '
template1() ::= <<
    This is the first line
    This is the second
>>'
        $result | Invoke-StringTemplate | Should Be "    This is the first line`r`n    this is the second"
    }
}
