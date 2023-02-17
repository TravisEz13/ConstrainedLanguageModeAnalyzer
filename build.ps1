Invoke-ScriptAnalyzer -Path "$PSScriptRoot\testFiles\*" `
            -CustomizedRulePath (Resolve-Path $PSScriptRoot\ConstrainedLanguageModeAnalyzer/ConstrainedLanguageModeAnalyzer.psm1) `
            -ExcludeRule PS*
