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
                $addTypeParameters = [System.Management.Automation.Language.StaticParameterBinder]::BindCommand($targetAst)
                $typeDefinitionParameter = $addTypeParameters.BoundParameters.TypeDefinition

                ## If it's not a constant value, check if it's a variable with a constant value
                if(-not $typeDefinitionParameter.ConstantValue)
                {
                    if($addTypeParameters.BoundParameters.TypeDefinition.Value -is [System.Management.Automation.Language.VariableExpressionAst])
                    {
                        $variableName = $addTypeParameters.BoundParameters.TypeDefinition.Value.VariablePath.UserPath
                        $constantAssignmentForVariable = $ScriptBlockAst.FindAll( {
                            param(
                                [System.Management.Automation.Language.Ast] $Ast
                            )

                            $assignmentAst = $Ast -as [System.Management.Automation.Language.AssignmentStatementAst]
                            if($assignmentAst -and
                               ($assignmentAst.Left.VariablePath.UserPath -eq $variableName) -and
                               ($assignmentAst.Right.Expression -is [System.Management.Automation.Language.ConstantExpressionAst]))
                            {
                                return $true
                            }
                        }, $true)

                        if($constantAssignmentForVariable)
                        {
                            return $false
                        }
                        else
                        {
                            return $true
                        }
                    }

                    return $true
                }
            }
        }
    }

    $foundNode = $ScriptBlockAst.Find($predicate, $false)
    if($foundNode)
    {
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
            "Message"  = "Add-Type is not allowed in constrained language mode"
            "Extent"   = $foundNode.Extent
            "RuleName" = "CLM.AddType"
            "Severity" = "Error" }
    }
}


<#
.DESCRIPTION
    Finds instances of dangerous methods, which can be used to invoke arbitrary
    code if supplied with untrusted input.
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
    Finds instances of dangerous methods, which can be used to invoke arbitrary
    code if supplied with untrusted input.
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

<#
.DESCRIPTION
    Finds instances of dynamic static property access, which can be vulnerable to property injection if
    supplied with untrusted user input.
#>
function Measure-PropertyInjection
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

    ## Finds MemberExpressionAst that uses a non-constant member
    [ScriptBlock] $predicate = {
        param ([System.Management.Automation.Language.Ast] $Ast)

        $targetAst = $Ast -as [System.Management.Automation.Language.MemberExpressionAst]
        $methodAst = $Ast -as [System.Management.Automation.Language.InvokeMemberExpressionAst]
        if($targetAst -and (-not $methodAst))
        {
            if(-not ($targetAst.Member -is [System.Management.Automation.Language.ConstantExpressionAst]))
            {
                ## This is not constant access, therefore dangerous
                return $true
            }
        }
    }

    $foundNode = $ScriptBlockAst.Find($predicate, $false)
    if($foundNode)
    {
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
            "Message"  = "Possible property access injection via dynamic member access. Untrusted input can cause " +
                         "arbitrary static properties to be accessed: " + $foundNode.Extent
            "Extent"   = $foundNode.Extent
            "RuleName" = "InjectionRisk.StaticPropertyInjection"
            "Severity" = "Warning" }
    }
}


<#
.DESCRIPTION
    Finds instances of dynamic method invocation, which can be used to invoke arbitrary
    methods if supplied with untrusted input.
#>
function Measure-MethodInjection
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

    ## Finds MemberExpressionAst nodes that don't invoke a constant expression
    [ScriptBlock] $predicate = {
        param ([System.Management.Automation.Language.Ast] $Ast)

        $targetAst = $Ast -as [System.Management.Automation.Language.InvokeMemberExpressionAst]
        if($targetAst)
        {
            if(-not ($targetAst.Member -is [System.Management.Automation.Language.ConstantExpressionAst]))
            {
                return $true
            }
        }
    }

    $foundNode = $ScriptBlockAst.Find($predicate, $false)
    if($foundNode)
    {
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
            "Message"  = "Possible property access injection via dynamic member access. Untrusted input can cause " +
                "arbitrary static properties to be accessed: " + $foundNode.Extent
            "Extent"   = $foundNode.Extent
            "RuleName" = "InjectionRisk.MethodInjection"
            "Severity" = "Warning" }
    }
}
