    # Updated: 20160824 - Removed unknown Action parameter
    function New-NSLBVServerRewritePolicyBinding {
        <#
        .SYNOPSIS
            Configure a new Rewrite Policy binding for the specified Load Balancing vSerer
        .DESCRIPTION
            Configure a new Rewrite Policy binding for the specified Load Balancing vSerer
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER vServerName
            Name of the vServer
        .PARAMETER PolicyName
            Name of the rewrite policy that is to be bound to the vServer
        .PARAMETER BindPoint
            The bindpoint to which the policy is bound. Possible values = REQUEST, RESPONSE
        .PARAMETER Priority
            Priority given to the policy binding
        .PARAMETER GotoPriorityExpression
            Expression specifying the priority of the next policy which will get evaluated if the current policy rule evaluates to True
        .PARAMETER InvokeLabelType
            Invoke Label Type to select ("PolicyLabel", "Load Balancing Virtual Server", "Content Switching Virtual Server")
        .EXAMPLE
            New-NSLBVServerRewritePolicyBinding -NSSession $NSSession -vServerName vsvr_lb_storefront -PolicyName rw_pol_default_store -Priority 100 -GoToPriorityExpression "END"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$vServerName,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$PolicyName,
            [Parameter(Mandatory=$true)][ValidateSet("REQUEST","RESPONSE")] [string]$BindPoint="REQUEST",
            [Parameter(Mandatory=$true)] [double]$Priority,
            # Expression specifying the priority of the next policy which will get evaluated if the current policy rule evaluates to True
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$GotoPriorityExpression="END",
            # Invoke Label Type to select ("PolicyLabel", "Load Balancing Virtual Server", "Content Switching Virtual Server")
            [Parameter(Mandatory=$false)][ValidateSet("reqvserver","resvserver","policylabel")] [string]$InvokeLabelType
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$vServerName;policyname=$PolicyName;priority=$Priority;bindpoint=$BindPoint}
        }
        Process {
#            if ($Invoke) {$payload.Add("invoke",$Invoke)}
            if (-not [string]::IsNullOrEmpty($GotoPriorityExpression)) {$payload.Add("gotopriorityexpression",$GotoPriorityExpression)}
            if (-not [string]::IsNullOrEmpty($InvokeLabelType)) {$payload.Add("labeltype",$InvokeLabelType)}

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType lbvserver_rewritepolicy_binding -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
