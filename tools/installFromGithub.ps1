# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
[cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]
    $Branch = 'main',
    [switch]
    $Clean
)

function New-Folder {
    param($Path)
    if (!(Test-Path $Path)) {
        $null = New-Item -Path $Path -ItemType Directory
    }
}

function Clean-Item {
    [cmdletbinding(SupportsShouldProcess = $true)]
    param($Path)
    if (Test-Path -Path $Path) {
        if ($PSCmdlet.ShouldProcess($Path)) {
            Remove-Item -Path $Path -Recurse -Force
        }
    }
}

function Download-File {
    [cmdletbinding(SupportsShouldProcess = $true)]
    param($Uri, $Outfile)
    if ($PSCmdlet.ShouldProcess("$Uri to $Outfile")) {
        Invoke-WebRequest -Uri $Uri -OutFile $Outfile
    }
}


if (!(get-module -ListAvailable PSScriptAnalyzer -ErrorAction Ignore | Where-Object { $_.version -ge '1.21' } )) {
    if ($PSCmdlet.ShouldProcess('Install PSScriptAnalyzer')) {
        Write-Verbose "installing scriptanalyzer" -Verbose
        Install-Module -Name PSScriptAnalyzer -Force
    }
}

$moduleName = 'ConstrainedLanguageModeAnalyzer'
$zipUrl = "https://github.com/TravisEz13/$ModuleName/archive/refs/heads/$Branch.zip"
$tempFile = Join-Path -Path ([System.io.path]::GetTempPath()) -ChildPath "CLM.zip"
$tempFolder = Join-Path -Path ([System.io.path]::GetTempPath()) -ChildPath "CLM-archive"

# $IsWindows is not defined in 5.1, so check if !linux and !macos to check for windows.
if (!$IsLinux -and !$IsMacOS) {
    $modulePath = Join-Path -Path ([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments)) -ChildPath "WindowsPowershell/Modules/$ModuleName"
}
else {
    $modulePath = Join-Path -Path ([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData)) -ChildPath "Powershell/Modules/$ModuleName"
}
Write-Verbose "ModulePath: $modulePath"

if ($Clean) {
    Clean-Item -Path $modulePath
}
Clean-Item -Path $tempFolder -WhatIf:$false

try {
    New-Folder -Path $modulePath
    Download-File -Uri $zipUrl -Outfile $tempFile
    Expand-Archive -Path $tempFile -DestinationPath $tempFolder
    if ($PSCmdlet.ShouldProcess($moduleName, 'Install')) {
        Get-ChildItem "$tempFolder/$moduleName-$Branch/$ModuleName/*" -Recurse | Copy-Item -Destination $modulePath
    }
    $module = Get-Module -ListAvailable ConstrainedLanguageModeAnalyzer
    if (!$module) {
        throw "There was an issues installing the module"
    }
    else {
        Write-Verbose -Message "module installed successfully" -Verbose
    }
}
finally {
    Clean-Item -Path $tempFile
    Clean-Item -Path $tempFolder
}
