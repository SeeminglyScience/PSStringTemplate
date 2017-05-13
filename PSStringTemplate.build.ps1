#requires -Module InvokeBuild
[CmdletBinding()]
param([string]$Configuration = 'Debug')

$script:ProjectRoot   = $PSScriptRoot
$script:ProjectName   = $script:ProjectRoot | Split-Path -Leaf
$script:Manifest      = Test-ModuleManifest -Path $script:ProjectRoot\module\$script:ProjectName.psd1 -ErrorAction 0 -WarningAction 0
$script:Version       = $script:Manifest.Version
$script:ReleaseFolder = "$script:ProjectRoot\Release\$script:ProjectName\$script:Version"
$script:ManifestPath  = "$script:ReleaseFolder\$script:ProjectName.psd1"
$script:BuildFolder   = "$script:ProjectRoot\src\$script:ProjectName\bin\$Configuration"
$script:Locale        = $PSCulture

# Load the module and invoke a script block in a different process so we don't have to restart
# the integrated console to rebuild dll's.
function InvokeWithModuleLoaded {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Action')]
        [ValidateNotNullOrEmpty()]
        [scriptblock]
        $ScriptBlock
    )
    $script = [scriptblock]::Create([System.Text.StringBuilder]::new().
            AppendFormat('Set-Location ''{0}''', $script:ProjectRoot).AppendLine().
            AppendFormat('Import-Module {0}', $script:ManifestPath).AppendLine().
            AppendLine($ScriptBlock).
            ToString())

    $job = Start-Job $script
    $job | Wait-Job | Receive-Job
    $job | Remove-Job
}

task Clean -Before BuildDll {
    exec { & dotnet clean }
    if (Test-Path $script:ProjectRoot\Release) {
        Remove-Item $script:ProjectRoot\Release -Recurse
    }
    $null = New-Item $script:ReleaseFolder -ItemType Directory
}

task BuildDll -Before BuildDocs {
    $null = exec { & dotnet build -c:$Configuration }
}

task BuildDocs -Before Build {
        $null = New-ExternalHelp -Path        $script:ProjectRoot\docs `
                                 -OutputPath "$script:ReleaseFolder\$script:Locale"
}

task Build -Before Test, BuildDebug {
    Copy-Item $script:BuildFolder\*.dll -Destination $script:ReleaseFolder

    Copy-Item $script:ProjectRoot\module\* -Destination $script:ReleaseFolder
}

task BuildDebug {
    Copy-Item $script:BuildFolder\*.pdb -Destination $script:ReleaseFolder
}

task Test -Before Install {
    InvokeWithModuleLoaded { Invoke-Pester }
}

task Install {
    $installBase = $Home
    if ($profile) { $installBase = $profile | Split-Path }
    $installPath = Join-Path $installBase -ChildPath 'Modules'
    
    if (-not (Test-Path $installPath)) {
        $null = New-Item $installPath -ItemType Directory
    }

    Copy-Item $script:ProjectRoot\Release\* -Destination $installPath -Force -Recurse
}

task . Build
