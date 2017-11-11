if (-not $PSVersionTable.PSEdition -or $PSVersionTable.PSEdition -eq 'Desktop') {
    Import-Module $PSScriptRoot/bin/Desktop/PSStringTemplate.dll
} else {
    Import-Module $PSScriptRoot/bin/Core/PSStringTemplate.dll
}
