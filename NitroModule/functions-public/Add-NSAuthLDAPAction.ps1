
    # Add-NSAuthLDAPAction is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    function Add-NSAuthLDAPAction {
        <#
        .SYNOPSIS
            Add a new NetScaler LDAP action
        .DESCRIPTION
            Add a new NetScaler LDAP action
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER LDAPActionName
            Name of the LDAP action
        .PARAMETER LDAPServerIP
            IP address assigned to the LDAP server
        .PARAMETER LDAPBaseDN
            Base (node) from which to start LDAP searches
        .PARAMETER LDAPBindDN
            Full distinguished name (DN) that is used to bind to the LDAP server
        .PARAMETER LDAPBindDNPassword,
            Password used to bind to the LDAP server
        .PARAMETER LDAPLoginName
            LDAP login name attribute. The NetScaler appliance uses the LDAP login name to query external LDAP servers or Active Directories
        .EXAMPLE
            Add-NSAuthLDAPAction -NSSession $Session -LDAPActionName "10.108.151.1_LDAP" -LDAPServerIP 10.8.115.245 -LDAPBaseDN "dc=xd,dc=local" -LDAPBindDN "administrator@xd.local" -LDAPBindDNPassword "passw0rd"
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$LDAPActionName,
            [Parameter(Mandatory=$true)] [string]$LDAPServerIP,
            [Parameter(Mandatory=$true)] [string]$LDAPBaseDN,
            [Parameter(Mandatory=$true)] [string]$LDAPBindDN,
            [Parameter(Mandatory=$true)] [string]$LDAPBindDNPassword,
            [Parameter(Mandatory=$false)] [string]$LDAPLoginName="sAMAccountName"
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload =  @{name=$LDAPActionName;serverip=$LDAPServerIP;ldapbase=$LDAPBaseDN;ldapbinddn=$LDAPBindDN;ldapbinddnpassword=$LDAPBindDNPassword;ldaploginname=$LDAPLoginName}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType authenticationldapaction -Payload $payload  

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
