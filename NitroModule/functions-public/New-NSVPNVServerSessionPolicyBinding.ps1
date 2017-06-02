    # New-NSVPNVServerSessionPolicyBinding is part of the Citrix NITRO Module
    function New-NSVPNVServerSessionPolicyBinding {
        <#
        .SYNOPSIS
            Bind VPN session policy to VPN virtual server
        .DESCRIPTION
            Bind VPN session policy to VPN virtual server
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER VirtualServerName
            Name of the virtual server
        .PARAMETER SessionPolicyName
            The name of the policy, if any, bound to the vpn vserver
        .PARAMETER Priority
            The priority, if any, of the vpn vserver policy
        .EXAMPLE
            New-NSVPNVServerSessionPolicyBinding -NSSession $Session -VirtualServerName "myVPNVirtualServer" -SessionPolicyName "PL_OS_10.108.151.3" -Priority "100"
        .EXAMPLE    
            New-NSVPNVServerSessionPolicyBinding -NSSession $Session -VirtualServerName "myVPNVirtualServer" -SessionPolicyName "PL_WB_10.108.151.3" -Priority "100"
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$VirtualServerName,
            [Parameter(Mandatory=$true)] [string]$SessionPolicyName,
            [Parameter(Mandatory=$false)] [string]$Priority="100"
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload = @{name=$VirtualServerName;policy=$SessionPolicyName;priority=$Priority}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType vpnvserver_vpnsessionpolicy_binding -Payload $payload -Action add 

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
