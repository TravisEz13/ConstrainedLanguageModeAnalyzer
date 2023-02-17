# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

if ((get-module -ListAvailable PSScriptAnalyzer -ErrorAction Stop)) {
    Install-Module -Name PSScriptAnalyzer -Force
}

Invoke-ScriptAnalyzer -Path "$PSScriptRoot\testFiles\*" `
    -CustomizedRulePath (Resolve-Path $PSScriptRoot\ConstrainedLanguageModeAnalyzer/ConstrainedLanguageModeAnalyzer.psm1) `
    -ExcludeRule PS*
