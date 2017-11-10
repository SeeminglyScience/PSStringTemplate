if (-not (Get-Module PSStringTemplate -ea 0)) {
    Import-Module $PSScriptRoot\..\Release\PSStringTemplate\*\PSStringTemplate.psd1 -Force
}

Describe 'Template invocation tests' {
    It 'can invoke a parameterless template' {
        Invoke-StringTemplate -Definition 'This is a pointless template.' | 
            Should Be 'This is a pointless template.'
    }
    It 'can map object properties as arguments' {
        Get-Command Get-ChildItem |
            Invoke-StringTemplate -Definition '<Name> - <CommandType>' |
            Should Be 'Get-ChildItem - Cmdlet'
    }
    It 'can map many objects to a single template' {
        $result = (Get-Item ..\)[0] |
            Get-Member -MemberType Method |
            Where-Object Name -Match '^Enumerate' |
            Invoke-StringTemplate -Definition '<TypeName> - <Name> - <MemberType>'
        $result -join [Environment]::NewLine | Should Be @'
System.IO.DirectoryInfo - EnumerateDirectories - Method
System.IO.DirectoryInfo - EnumerateFiles - Method
System.IO.DirectoryInfo - EnumerateFileSystemInfos - Method
'@
    }
    It 'can invoke multiple templates from the pipeline' {
        $group = New-StringTemplateGroup -Definition '
            template1(Name) ::= "<Name>"
            template2(CommandType) ::= "<CommandType>"'
        
        $group.Templates |
            Invoke-StringTemplate (Get-Command Get-ChildItem) |
            Should Be 'Get-ChildItem','Cmdlet'
    }
    It 'can invoke one template from a group from the pipeline' {
        $group = New-StringTemplateGroup -Definition '
            template1(Name) ::= "<Name>"
            template2(CommandType) ::= "<CommandType>"'
        $group |
            Invoke-StringTemplate -Name template1 (Get-Command Get-ChildItem) |
            Should Be 'Get-ChildItem'
    }
    It 'can map a dictionary as parameters' {
        Invoke-StringTemplate -Definition '<One>, <Two>' @{ One = '1'; Two = '2' } |
            Should Be '1, 2'
    }
    It 'can map a "property-like" method as a parameter' {
        Invoke-StringTemplate -Definition '<Parameters>' ([scriptblock].GetMethod('Create')) |
            Should Be 'System.String script'
    }
    It 'cannot map a method that does not start with Get' {
        $cmdlet = New-Object PSStringTemplate.NewStringTemplateGroupCommand -Property @{ Definition = 'Test' }
        Invoke-StringTemplate -Definition '<Invoke>' $cmdlet | Should BeNullOrEmpty
    }
    It 'cannot map accessors as parameters' {
        $cmdlet = New-Object PSStringTemplate.NewStringTemplateGroupCommand -Property @{ Definition = 'Test' }
        Invoke-StringTemplate -Definition '<_Definition>' $cmdlet | Should BeNullOrEmpty
    }
    It 'can map static properties when input is a type' {
        [DateTime] |
            Invoke-StringTemplate -Definition '<Now>' |
            Should Not BeNullOrEmpty
    }
    It 'adds instance properties of RuntimeType as well when bound by input' {
        [DateTime] |
            Invoke-StringTemplate -Definition '<IsPublic>' |
            Should Be True
    }
    It 'can map static properties using the type adapter' {
        Invoke-StringTemplate -Definition '<r.DefaultRunspace.RunspaceStateInfo.State>' @{
            r = [runspace]
        } | Should Be 'Opened'
    }
    It 'adds instance properties as well as static using the adapter' {
        Invoke-StringTemplate -Definition '<r.IsPublic>' @{ r = [runspace] } |
            Should Be True
    }
    It 'can format date using the date renderer' {
        Invoke-StringTemplate -Definition '<d; format="yyyy.MM.dd">' @{ d = [DateTime]'1/1/90' } |
            Should Be '1990.01.01'
    }
}
