    # Add-NSVPNSessionPolicy is part of the Citrix NITRO Module
    function Add-NSVPNSessionPolicy {
        <#
        .SYNOPSIS
            Add VPN Session policy resources
        .DESCRIPTION
            Add VPN Session policy resources
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER SessionActionName
            Action to be applied by the new session policy if the rule criteria are met.
        .PARAMETER SessionPolicyName
            Name for the new session policy that is applied after the user logs on to Access Gateway.
        .PARAMETER SessionRuleExpression
            Expression, or name of a named expression, specifying the traffic that matches the policy.
            Can be written in either default or classic syntax. 
        .EXAMPLE
            Add-NSVPNSessionPolicy -NSSession $Session -SessionActionName "AC_OS_10.108.151.1_S_" -SessionPolicyName "PL_OS_10.108.151.1" -SessionRuleExpression "REQ.HTTP.HEADER User-Agent CONTAINS CitrixReceiver || REQ.HTTP.HEADER Referer NOTEXISTS"
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$SessionActionName,
            [Parameter(Mandatory=$true)] [string]$SessionPolicyName,
            [Parameter(Mandatory=$true)] [string]$SessionRuleExpression
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload = @{name=$SessionPolicyName;action=$SessionActionName;rule=$SessionRuleExpression}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType vpnsessionpolicy -Payload $payload -Action add 

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
