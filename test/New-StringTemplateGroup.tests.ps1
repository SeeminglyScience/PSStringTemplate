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
Describe 'Group exception handling tests' {
    # Verifies the parse message displays the correct code, highlights the right
    # character, and relays the correct message from the engine.
    function ShouldThrowParse {
        [CmdletBinding()]
        param(
            [string]$ContextMessage,
            [string]$Body,
            [single]$Offset = 0,
            [Parameter(ValueFromPipeline)][scriptblock]$InputObject
        )
        process {
            $exceptionString = '(' +[regex]::Escape($ContextMessage) + ')' +
                               ".*\+\s{$($ContextMessage.Length + $Offset)}~"
            if ($Body) {
                $exceptionString += '.*{0}' -f $Body
            }

            try {
                $null = & $InputObject
            } catch {
                $actualMessage = $_.Exception.Message
            }
            if ($actualMessage) {
                $actualMessage | Should Match ('(?s)' + $exceptionString)
            }
        }
    }
    It 'displays TemplateGroupCompiletimeMessage' {
        $definition = 'a()::='
        { New-StringTemplateGroup -Definition $definition } |
            ShouldThrowParse $definition -Body 'missing template at ''\<EOF\>' -Offset 1
    }
    It 'displays TemplateLexerMessage' {
        $definition = 'a(x)::= "<x; separator=\",>"'
        { New-StringTemplateGroup -Definition $definition } |
            ShouldThrowParse '<x; separator=",>' -Body 'EOF in string' -Offset 1
    }
    It 'displays TemplateLexerMessage with multiple lines' {
        $definition = '
        a(x)::= "<x>"
        b(x)::= "<x; separator=\",>"
        c(x)::= "<x>'
        { New-StringTemplateGroup -Definition $definition } |
            ShouldThrowParse '<x; separator=",>' -Body 'EOF in string' -Offset 1
    }
    It 'displays TemplateCompiletimeMessage' {
        { New-StringTemplateGroup -Definition 'a(x)::= "<x"' } |
            ShouldThrowParse '<x' -Body 'premature EOF' -Offset 1
    }
    It 'highlights the right character mid context' {
        { New-StringTemplateGroup -Definition 'a(x)::= "<sep;;>"' } |
            ShouldThrowParse '<sep;;>' -Body 'mismatched input '';'' expecting ID' -Offset -1

    }
}
