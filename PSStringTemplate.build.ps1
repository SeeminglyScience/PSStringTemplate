#requires -Module InvokeBuild
[CmdletBinding()]
param([string]$Configuration = 'Debug')

$ProjectRoot   = $PSScriptRoot
$ProjectName   = $ProjectRoot | Split-Path -Leaf
$Manifest      = Test-ModuleManifest -Path $ProjectRoot\module\$ProjectName.psd1 -ErrorAction 0 -WarningAction 0
$Version       = $Manifest.Version
$ReleaseFolder = "$ProjectRoot\Release\$ProjectName\$Version"
$ManifestPath  = "$ReleaseFolder\$ProjectName.psd1"
$BuildFolder   = "$ProjectRoot\src\$ProjectName\bin\$Configuration"
$Locale        = $PSCulture

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
            AppendFormat('Set-Location ''{0}''', $ProjectRoot).AppendLine().
            AppendFormat('Import-Module {0}', $ManifestPath).AppendLine().
            AppendLine($ScriptBlock).
            ToString())

    $job = Start-Job $script
    $job | Wait-Job | Receive-Job
    $job | Remove-Job
}

task Clean -Before BuildDll {
    exec { & dotnet clean }
    if (Test-Path $ProjectRoot\Release) {
        Remove-Item $ProjectRoot\Release -Recurse
    }
    $null = New-Item $ReleaseFolder -ItemType Directory
}

task BuildDll -Before BuildDocs {
    $null = exec { & dotnet build -c:$Configuration }
}

task BuildDocs -Before Build {
    $null = New-ExternalHelp -Path $ProjectRoot\docs -OutputPath "$ReleaseFolder\$Locale"
}

task Build -Before Test, BuildDebug {
    Copy-Item $BuildFolder\*.dll -Destination $ReleaseFolder
    Copy-Item $ProjectRoot\module\* -Destination $ReleaseFolder
}

task BuildDebug {
    Copy-Item $BuildFolder\*.pdb -Destination $ReleaseFolder
}

task Test -Before Install, Publish {
    InvokeWithModuleLoaded { Invoke-Pester }
}

task Install {
    $installBase = $Home
    if ($profile) { $installBase = $profile | Split-Path }
    $installPath = Join-Path $installBase -ChildPath 'Modules'
    
    if (-not (Test-Path $installPath)) {
        $null = New-Item $installPath -ItemType Directory
    }

    Copy-Item $ProjectRoot\Release\* -Destination $installPath -Force -Recurse
}

task Publish {
    if ($Configuration -eq 'Debug') {
        throw 'Configuration must be "Release" to publish!'
    }

    if (-not (Test-Path $env:USERPROFILE\.PSGallery\apikey.xml)) {

        throw 'Could not find PSGallery API key!'
    }
    
    $apiKey = (Import-Clixml $env:USERPROFILE\.PSGallery\apikey.xml).GetNetworkCredential().Password
    Publish-Module -Name $ReleaseFolder -NuGetApiKey $apiKey -Confirm
}

task . Build
