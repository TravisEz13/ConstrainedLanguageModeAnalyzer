# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#####################################################################
##
## Rules
##
######################################################################

function Measure-AddType
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    [ScriptBlock] $predicate = {
        param ([System.Management.Automation.Language.Ast] $Ast)

        $targetAst = $Ast -as [System.Management.Automation.Language.CommandAst]
        if($targetAst)
        {
            if($targetAst.CommandElements[0].Extent.Text -eq "Add-Type")
            {
                return $true
            }
        }
    }

    $foundNode = $ScriptBlockAst.Find($predicate, $false)
    if($foundNode)
    {
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
            "Message"  = "Add-Type is only allowed in CLM if it ONLY loads an assembly allowed by policy."
            "Extent"   = $foundNode.Extent
            "RuleName" = "CLM.AddType"
            "Severity" = "Warning" }
    }
}


<#
.DESCRIPTION
    Finds instances of disallowed static method calls
#>
function Measure-DangerousMethod
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    [ScriptBlock] $predicate = {
        param ([System.Management.Automation.Language.Ast] $Ast)

        $targetAst = $Ast -as [System.Management.Automation.Language.InvokeMemberExpressionAst]
        if($targetAst)
        {
            if($targetAst.Member.Extent.Text -in ("ToString"))
            {
                return $false
            }

            $allowedTypes = (get-content -raw "$psscriptroot/allowedTypes.json" | ConvertFrom-Json) | ForEach-Object {
                "[$_]"
            }

            Write-Verbose $targetAst.Expression.Extent.Text -Verbose
            if(($targetAst.Expression.Extent.Text -in $allowedTypes))
            {
                return $false
            }
            return $true
        }
    }

    $foundNode = $ScriptBlockAst.Find($predicate, $false)
    if($foundNode)
    {
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
            "Message"  = "Method calls are only allowed for specific types in CLM"
            "Extent"   = $foundNode.Extent
            "RuleName" = "CLM.MethodCall.$($foundNode.Expression.Extent.Text)"
            "Severity" = "Error" }
    }
}

<#
.DESCRIPTION
    Finds instances of dotsourcing, which can cause issues with CLM if they are across language modes.
#>
function Measure-Dotsource
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    [ScriptBlock] $predicate = {
        param ([System.Management.Automation.Language.Ast] $Ast)

        $targetAst = $Ast -as [System.Management.Automation.Language.CommandAst]
        if($targetAst)
        {
            if($targetAst.InvocationOperator -eq 'Dot')
            {
                return $true
            }
        }
    }

    $foundNode = $ScriptBlockAst.Find($predicate, $false)
    if($foundNode)
    {
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
            "Message"  = "DotSourcing accross language modes is not allowed" +
                " (language modes can only be detected at runtime)"
            "Extent"   = $foundNode.Extent
            "RuleName" = "CLM.Dotsource"
            "Severity" = "Warning" }
    }
}
