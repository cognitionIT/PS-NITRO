    # New-NSVPNVServerAuthLDAPPolicyBinding is part of the Citrix NITRO Module
    function New-NSVPNVServerAuthLDAPPolicyBinding {
        <#
        .SYNOPSIS
            Bind authentication LDAP policy to VPN virtual server
        .DESCRIPTION
            Bind authentication LDAP policy to VPN virtual server
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER VirtualServerName
            Name of the VPN virtual server
        .PARAMETER LDAPPolicyName
            The name of the policy to be bound to the vpn vserver
        .EXAMPLE
            New-NSVPNVServerAuthLDAPPolicyBinding -NSSession $Session -VirtualServerName "myVPNVirtualServer" -LDAPPolicyName "10.108.151.1_LDAP_pol"
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$VirtualServerName,
            [Parameter(Mandatory=$true)] [string]$LDAPPolicyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload = @{name=$VirtualServerName;policy=$LDAPPolicyName}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType vpnvserver_authenticationldappolicy_binding -Payload $payload -Action add 

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
