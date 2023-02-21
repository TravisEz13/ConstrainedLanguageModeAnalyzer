# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

if (!(get-module -ListAvailable PSScriptAnalyzer -ErrorAction Stop)) {
    Install-Module -Name PSScriptAnalyzer -Force
}

Import-Module PSScriptAnalyzer

# To analyze files
Invoke-ClmAnalyzer -Path "$PSScriptRoot\testFiles\*"

# To analyze a script definition
Invoke-ClmAnalyzer -ScriptDefinition '. test.ps1'
