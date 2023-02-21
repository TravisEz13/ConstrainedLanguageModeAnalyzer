# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Describe "CLM analyzere"{
    BeforeAll {
        $testRoot = (Resolve-Path "$PSScriptRoot\..\testFiles").ProviderPath
        $modulePath = (Resolve-Path "$PSScriptRoot\..\ConstrainedLanguageModeAnalyzer").ProviderPath
        Import-Module $modulePath -force
    }

    Context "Should detect" {

        It "should detect add-type" {
            $results = Invoke-ClmAnalyzer -Path "$testRoot\hasIssues\AddType.ps1"
            $results | Should -Not -BeNullOrEmpty
            $results.count | Should -Be 1
            $results[0].RuleName | Should -Be 'CLM.AddType'
            $results[0].Severity | Should -Be 'Warning'
            $results[0].Line | Should -Be 3
        }
        It "should detect static method on [math]" {
            $results = Invoke-ClmAnalyzer -Path "$testRoot\hasIssues\mathStaticMethod.ps1"
            $results | Should -Not -BeNullOrEmpty
            $results.count | Should -Be 1
            $results[0].RuleName | Should -Be 'CLM.MethodCall.[Math]'
            $results[0].Severity | Should -Be 'Error'
            $results[0].Line | Should -Be 3
        }
        It "should detect a dotsource" {
            $results = Invoke-ClmAnalyzer -Path "$testRoot\hasIssues\dotsource.ps1"
            $results | Should -Not -BeNullOrEmpty
            $results.count | Should -Be 1
            $results[0].RuleName | Should -Be 'CLM.Dotsource'
            $results[0].Severity | Should -Be 'Warning'
            $results[0].Line | Should -Be 3
        }
        It "should detect a method call" {
            $results = Invoke-ClmAnalyzer -Path "$testRoot\hasIssues\methodCall.ps1"
            $results | Should -Not -BeNullOrEmpty
            $results.count | Should -Be 1
            $results[0].RuleName | Should -match 'CLM.MethodCall.*'
            $results[0].Severity | Should -Be 'Error'
            $results[0].Line | Should -Be 3
        }
        It "should detect pwsh -file <file> <arg>" -Pending {
            $results = Invoke-ClmAnalyzer -Path "$testRoot\hasIssues\callPwsh.ps1"
            $results | Should -Not -BeNullOrEmpty
            $results.count | Should -Be 1
            $results[0].RuleName | Should -match 'CLM.MethodCall.*'
            $results[0].Severity | Should -Be 'Error'
            $results[0].Line | Should -Be 3
        }
        It "should detect new-object" {
            $results = Invoke-ClmAnalyzer -Path "$testRoot\hasIssues\newObject.ps1"
            $results | Should -Not -BeNullOrEmpty
            $results.count | Should -Be 1
            $results[0].RuleName | Should -match 'CLM.NewObject'
            $results[0].Severity | Should -Be 'Warning'
            $results[0].Line | Should -Be 3
        }
    }
    Context "should not detect" {
        It "should not detect static method on [int32]" {
            $results = Invoke-ClmAnalyzer -Path "$testRoot\noIssues\staticMethod.ps1"
            $results | Should -BeNullOrEmpty
        }
        It "should not detect <file>" -TestCases @(
            @{File='newObjectNamed.ps1'}
            @{File='newObjectPositional.ps1'}
        ) {
            param($File)
            $results = Invoke-ClmAnalyzer -Path "$testRoot\noIssues\$File"
            $results | Should -BeNullOrEmpty
        }
    }
}
