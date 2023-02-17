# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Describe "CLM analyzere"{
    BeforeAll {
        $testRoot = (Resolve-Path "$PSScriptRoot\..\testFiles").ProviderPath
        $modulePath = (Resolve-Path "$PSScriptRoot\..\ConstrainedLanguageModeAnalyzer/ConstrainedLanguageModeAnalyzer.psm1").ProviderPath
    }

    Context "Should detect" {

        It "should detect add-type" {
            $results = Invoke-ScriptAnalyzer -Path "$testRoot\hasIssues\AddType.ps1" `
                -CustomizedRulePath $modulePath `
                -ExcludeRule PS*
            $results | Should -Not -BeNullOrEmpty
            $results.count | Should -Be 1
            $results[0].RuleName | Should -Be 'CLM.AddType'
            $results[0].Severity | Should -Be 'Warning'
            $results[0].Line | Should -Be 3
        }
        It "should detect static method on [math]" {
            $results = Invoke-ScriptAnalyzer -Path "$testRoot\hasIssues\mathStaticMethod.ps1" `
                -CustomizedRulePath $modulePath `
                -ExcludeRule PS*
            $results | Should -Not -BeNullOrEmpty
            $results.count | Should -Be 1
            $results[0].RuleName | Should -Be 'CLM.MethodCall.[Math]'
            $results[0].Severity | Should -Be 'Error'
            $results[0].Line | Should -Be 3
        }
        It "should detect a dotsource" {
            $results = Invoke-ScriptAnalyzer -Path "$testRoot\hasIssues\dotsource.ps1" `
                -CustomizedRulePath $modulePath `
                -ExcludeRule PS*
            $results | Should -Not -BeNullOrEmpty
            $results.count | Should -Be 1
            $results[0].RuleName | Should -Be 'CLM.Dotsource'
            $results[0].Severity | Should -Be 'Warning'
            $results[0].Line | Should -Be 3
        }
        It "should detect a method call" {
            $results = Invoke-ScriptAnalyzer -Path "$testRoot\hasIssues\methodCall.ps1" `
                -CustomizedRulePath $modulePath `
                -ExcludeRule PS*
            $results | Should -Not -BeNullOrEmpty
            $results.count | Should -Be 1
            $results[0].RuleName | Should -match 'CLM.MethodCall.*'
            $results[0].Severity | Should -Be 'Error'
            $results[0].Line | Should -Be 3
        }
        It "should detect pwsh -file <file> <arg>" -Pending {
            $results = Invoke-ScriptAnalyzer -Path "$testRoot\hasIssues\callPwsh.ps1" `
                -CustomizedRulePath $modulePath `
                -ExcludeRule PS*
            $results | Should -Not -BeNullOrEmpty
            $results.count | Should -Be 1
            $results[0].RuleName | Should -match 'CLM.MethodCall.*'
            $results[0].Severity | Should -Be 'Error'
            $results[0].Line | Should -Be 3
        }
    }
    Context "should not detect" {
        It "should not detect static method on [int32]" {
            $results = Invoke-ScriptAnalyzer -Path "$testRoot\noIssues\staticMethod.ps1" `
                -CustomizedRulePath $modulePath `
                -ExcludeRule PS*
            $results | Should -BeNullOrEmpty
        }
    }
}
