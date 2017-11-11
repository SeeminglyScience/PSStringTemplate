#requires -Module InvokeBuild, Pester, PlatyPS -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]
    $Configuration = 'Debug',

    [switch]
    $GenerateCodeCoverage
)

$moduleName = 'PSStringTemplate'
$manifest   = Test-ModuleManifest -Path          $PSScriptRoot\module\$moduleName.psd1 `
                                  -ErrorAction   Ignore `
                                  -WarningAction Ignore

$script:Settings = @{
    Name          = $moduleName
    Manifest      = $manifest
    Version       = $manifest.Version
    ShouldTest    = $true
}

$script:Folders  = @{
    PowerShell = "$PSScriptRoot\module"
    CSharp     = "$PSScriptRoot\src"
    Build      = '{0}\src\{1}*\bin\{2}' -f $PSScriptRoot, $moduleName, $Configuration
    Release    = '{0}\Release\{1}\{2}' -f $PSScriptRoot, $moduleName, $manifest.Version
    Docs       = "$PSScriptRoot\docs"
    Test       = "$PSScriptRoot\test"
    Results    = "$PSScriptRoot\testresults"
}

$script:Discovery = @{
    HasDocs       = Test-Path ('{0}\{1}\*.md' -f $Folders.Docs, $PSCulture)
    HasTests      = Test-Path ('{0}\*.Tests.ps1' -f $Folders.Test)
    IsUnix        = $PSVersionTable.PSEdition -eq "Core" -and -not $IsWindows
}

$tools = "$PSScriptRoot\tools"
$script:dotnet = & $tools\GetDotNet.ps1 -Unix:$Discovery.IsUnix

if ($GenerateCodeCoverage.IsPresent) {
    $script:openCover = & $tools\GetOpenCover.ps1
}


task Clean {
    if ($PSScriptRoot -and (Test-Path $PSScriptRoot\Release)) {
        Remove-Item $PSScriptRoot\Release -Recurse
    }

    $null = New-Item $Folders.Release -ItemType Directory
    if (Test-Path $Folders.Results) {
        Remove-Item $Folders.Results -Recurse
    }

    $null = New-Item $Folders.Results -ItemType Directory
    & $dotnet clean
}

task BuildDocs -If { $Discovery.HasDocs } {
    $sourceDocs  = "$PSScriptRoot\docs\$PSCulture"
    $releaseDocs = '{0}\{1}' -f $Folders.Release, $PSCulture

    $null = New-Item $releaseDocs -ItemType Directory -Force -ErrorAction SilentlyContinue
    if ($Discovery.IsUnix) {
        Write-Host -ForegroundColor Green 'The mkdir errors below are fine, they''re due to a alias in platyPS'
    }
    $null = New-ExternalHelp -Path $sourceDocs -OutputPath $releaseDocs
}

task BuildDll {
    if (-not $Discovery.IsUnix) {
        & $dotnet build --configuration $Configuration --framework net452
    }
    & $dotnet build --configuration $Configuration --framework netcoreapp2.0
}

task CopyToRelease  {
    $powershellSource  = '{0}\*' -f $Folders.PowerShell
    $release           = $Folders.Release
    $releaseDesktopBin = "$release\bin\Desktop"
    $releaseCoreBin    = "$release\bin\Core"
    $sourceDesktopBin  = '{0}\net452' -f $Folders.Build
    $sourceCoreBin     = '{0}\netcoreapp2.0' -f $Folders.Build
    Copy-Item -Path $powershellSource -Destination $release -Recurse -Force

    if (-not $Discovery.IsUnix) {
        $null = New-Item $releaseDesktopBin -Force -ItemType Directory
        Copy-Item -Path $sourceDesktopBin\PSStringTemplate* -Destination $releaseDesktopBin -Force
        Copy-Item -Path $sourceDesktopBin\Antlr* -Destination $releaseDesktopBin -Force
    }

    $null = New-Item $releaseCoreBin -Force -ItemType Directory
    Copy-Item -Path $sourceCoreBin\PSStringTemplate* -Destination $releaseCoreBin -Force
    Copy-Item -Path $sourceDesktopBin\Antlr* -Destination $releaseCoreBin -Force
}

task DoTest -If { $Discovery.HasTests -and $Settings.ShouldTest } {
    if ($Discovery.IsUnix) {
        $scriptString = '
            $projectPath = "{0}"
            Invoke-Pester "$projectPath" -OutputFormat NUnitXml -OutputFile "$projectPath\testresults\pester.xml"
            ' -f $PSScriptRoot
    } else {
        $scriptString = '
            Set-ExecutionPolicy Bypass -Force -Scope Process
            $projectPath = "{0}"
            Invoke-Pester "$projectPath" -OutputFormat NUnitXml -OutputFile "$projectPath\testresults\pester.xml"
            ' -f $PSScriptRoot
    }

    $encodedCommand =
        [convert]::ToBase64String(
            [System.Text.Encoding]::Unicode.GetBytes(
                $scriptString))

    $powershell = (Get-Command powershell).Source

    if ($GenerateCodeCoverage.IsPresent) {
        if ($Discovery.IsUnix) {
            throw 'Generating code coverage from .NET core is currently unsupported.'
        }
        # OpenCover needs full pdb's. I'm very open to suggestions for streamlining this...
        & $dotnet clean
        & $dotnet build --configuration $Configuration --framework net452 /p:DebugType=Full

        $moduleName = $Settings.Name
        $release = '{0}\bin\Desktop\{1}' -f $Folders.Release, $moduleName
        $coverage = '{0}\net452\{1}' -f $Folders.Build, $moduleName

        Rename-Item "$release.pdb" -NewName "$moduleName.pdb.tmp"
        Rename-Item "$release.dll" -NewName "$moduleName.dll.tmp"
        Copy-Item "$coverage.pdb" "$release.pdb"
        Copy-Item "$coverage.dll" "$release.dll"

        & $openCover `
            -target:$powershell `
            -register:user `
            -output:$PSScriptRoot\testresults\opencover.xml `
            -hideskipped:all `
            -filter:+[PSStringTemplate*]* `
            -targetargs:"-NoProfile -EncodedCommand $encodedCommand"

        Remove-Item "$release.pdb"
        Remove-Item "$release.dll"
        Rename-Item "$release.pdb.tmp" -NewName "$moduleName.pdb"
        Rename-Item "$release.dll.tmp" -NewName "$moduleName.dll"
    } else {
        & $powershell -NoProfile -EncodedCommand $encodedCommand
    }
}

task DoInstall {
    $sourcePath  = '{0}\*' -f $Folders.Release
    $installBase = $Home
    if ($profile) { $installBase = $profile | Split-Path }
    $installPath = '{0}\Modules\{1}\{2}' -f $installBase, $Settings.Name, $Settings.Version

    if (-not (Test-Path $installPath)) {
        $null = New-Item $installPath -ItemType Directory
    }

    Copy-Item -Path $sourcePath -Destination $installPath -Force -Recurse
}

task DoPublish {
    if ($Configuration -eq 'Debug') {
        throw 'Configuration must not be Debug to publish!'
    }

    if (-not (Test-Path $env:USERPROFILE\.PSGallery\apikey.xml)) {
        throw 'Could not find PSGallery API key!'
    }

    $apiKey = (Import-Clixml $env:USERPROFILE\.PSGallery\apikey.xml).GetNetworkCredential().Password
    Publish-Module -Name $Folders.Release -NuGetApiKey $apiKey -Confirm
}

task Build -Jobs Clean, BuildDll, CopyToRelease, BuildDocs

task Test -Jobs Build, DoTest

task PreRelease -Jobs Test

task Install -Jobs PreRelease, DoInstall

task Publish -Jobs PreRelease, DoPublish

task . Build

