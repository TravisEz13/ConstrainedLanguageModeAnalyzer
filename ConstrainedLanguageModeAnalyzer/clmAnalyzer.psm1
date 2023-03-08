# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

function Invoke-ClmAnalyzer {
    [CmdletBinding(DefaultParameterSetName='Path_SuppressedOnly', SupportsShouldProcess=$true, ConfirmImpact='Medium', HelpUri='https://go.microsoft.com/fwlink/?LinkId=525914')]
    param(
        [Parameter(ParameterSetName='Path_IncludeSuppressed', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Parameter(ParameterSetName='Path_SuppressedOnly', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('PSPath')]
        [ValidateNotNull()]
        [string]
        ${Path},

        [Parameter(ParameterSetName='ScriptDefinition_IncludeSuppressed', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Parameter(ParameterSetName='ScriptDefinition_SuppressedOnly', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [string]
        ${ScriptDefinition},

        [switch]
        ${RecurseCustomRulePath},

        [switch]
        ${IncludeDefaultRules},

        [ValidateNotNull()]
        [string[]]
        ${ExcludeRule},

        [ValidateNotNull()]
        [string[]]
        ${IncludeRule},

        [ValidateSet('Warning','Error','Information','ParseError')]
        [string[]]
        ${Severity},

        [switch]
        ${Recurse},

        [Parameter(ParameterSetName='Path_SuppressedOnly')]
        [Parameter(ParameterSetName='ScriptDefinition_SuppressedOnly')]
        [switch]
        ${SuppressedOnly},

        [Parameter(ParameterSetName='Path_IncludeSuppressed', Mandatory=$true)]
        [Parameter(ParameterSetName='ScriptDefinition_IncludeSuppressed', Mandatory=$true)]
        [switch]
        ${IncludeSuppressed},

        [Parameter(ParameterSetName='Path_IncludeSuppressed')]
        [Parameter(ParameterSetName='Path_SuppressedOnly')]
        [switch]
        ${Fix},

        [switch]
        ${EnableExit},

        [Alias('Profile')]
        [ValidateNotNull()]
        [System.Object]
        ${Settings},

        [switch]
        ${SaveDscDependency},

        [switch]
        ${ReportSummary})

    begin
    {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $rulePath = (Resolve-Path $PSScriptRoot\ConstrainedLanguageModeAnalyzer.psm1)

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('PSScriptAnalyzer\Invoke-ScriptAnalyzer', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters -CustomizedRulePath $rulePath }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
        finally {
            if ($null -ne $steppablePipeline) {
                $steppablePipeline.Clean()
            }
        }
    }
}
