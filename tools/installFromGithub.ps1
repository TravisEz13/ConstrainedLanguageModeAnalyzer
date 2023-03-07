[cmdletbinding(SupportsShouldProcess = $true)]
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
    param($Path)
    if (Test-Path -Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
    }
}

if (!(get-module -ListAvailable PSScriptAnalyzer -ErrorAction Ignore | Where-Object { $_.version -ge '1.21' } )) {
    Write-Verbose "installing scriptanalyzer" -Verbose
    Install-Module -Name PSScriptAnalyzer -Force
}

$moduleName = 'ConstrainedLanguageModeAnalyzer'
$zipUrl = "https://github.com/TravisEz13/$ModuleName/archive/refs/heads/$Branch.zip"
$tempFile = Join-Path -Path ([System.io.path]::GetTempPath()) -ChildPath "CLM.zip"
$tempFolder = Join-Path -Path ([System.io.path]::GetTempPath()) -ChildPath "CLM-archive"

$modulePath = Join-Path -Path ([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData)) -ChildPath "Powershell/Modules/$ModuleName"

if ($Clean) {
    Clean-Item -Path $modulePath
}
Clean-Item -Path $tempFolder

try {
    New-Folder -Path $modulePath
    Invoke-WebRequest -Uri $zipUrl -OutFile $tempFile
    Expand-Archive -Path $tempFile -DestinationPath $tempFolder
    Get-ChildItem "$tempFolder/$moduleName-$Branch/$ModuleName/*" -Recurse | Copy-Item -Destination $modulePath
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
