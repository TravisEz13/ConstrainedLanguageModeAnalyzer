# Constrained Language Mode (CLM) Analyzer

A module to use script analyzer to find potential issues with running your scripts in CLM

## Support

This is an experiment and I'm looking for feedback about the idea.
Issues are welcome, but there currently is no support for this module.
It is MIT licensed and provided as-is.

## Installation - Automated

If you plan to use this for PowerShell 5.1 and 7, you may need to install the module for both versions.

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/TravisEz13/ConstrainedLanguageModeAnalyzer/main/tools/installFromGithub.ps1 -outfile ./installFromGitHub.ps1
./installFromGithub.ps1 -Verbose
```

## Usage

### To analyze files

```powershell
Invoke-ClmAnalyzer -Path "$PSScriptRoot\testFiles\*"
```

### To analyze a script definition

```powershell
Invoke-ClmAnalyzer -ScriptDefinition '. test.ps1'
```

## Installation - Manual

Download the repo as a [zip](https://github.com/TravisEz13/ConstrainedLanguageModeAnalyzer/archive/refs/heads/main.zip) file and run the following in the resulting folder.
Be sure to run `unblock-file` on the zip file, before extracting it.

Install version 1.21 or newer of `PSScriptAnalyzer`.

```powershell
    Install-Module -Name PSScriptAnalyzer -Force
```

Manually import the module:

```powershell
Import-Module .\ConstrainedLanguageModeAnalyzer
```
