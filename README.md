# Constrained Language Mode (CLM) Analyzer

A module to use script analyzer to find potential issues with running your scripts in CLM

## Support

This is an experiment and I'm looking for feedback about the idea.
Issues are welcome, but there currently is no support for this module.
It is MIT licensed and provided as-is.

## Usage

Download the repo as a [zip](https://github.com/TravisEz13/ConstrainedLanguageModeAnalyzer/archive/refs/heads/main.zip) file and run the following in the resulting folder:

```powershell
if (!(get-module -ListAvailable PSScriptAnalyzer -ErrorAction Stop)) {
    Install-Module -Name PSScriptAnalyzer -Force
}

Import-Module .\ConstrainedLanguageModeAnalyzer

# To analyze files
Invoke-ClmAnalyzer -Path "$PSScriptRoot\testFiles\*"

# To analyze a script definition
Invoke-ClmAnalyzer -ScriptDefinition '. test.ps1'
```
