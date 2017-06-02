    function Update-NSAuthLDAPAction {
        <#
        .SYNOPSIS
            Update a new NetScaler LDAP action
        .DESCRIPTION
            Update a new NetScaler LDAP action
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
            Update-NSAuthLDAPAction -NSSession $Session -LDAPActionName "10.108.151.1_LDAP" -LDAPServerIP 10.8.115.245 -LDAPBaseDN "dc=xd,dc=local" -LDAPBindDN "administrator@xd.local" -LDAPBindDNPassword "passw0rd"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$LDAPActionName,
            [Parameter(Mandatory=$false)] [string]$LDAPServerIP,
            [Parameter(Mandatory=$false)] [string]$LDAPBaseDN,
            [Parameter(Mandatory=$false)] [string]$LDAPBindDN,
            [Parameter(Mandatory=$false)] [string]$LDAPBindDNPassword,
            [Parameter(Mandatory=$false)] [string]$LDAPLoginName="sAMAccountName"
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload =  @{name=$LDAPActionName}
        
        if (-not [string]::IsNullOrEmpty($LDAPServerIP)) 
        {
           $payload.Add("serverip",$LDAPServerIP)
        }
        if (-not [string]::IsNullOrEmpty($LDAPBaseDN)) 
        {
           $payload.Add("ldapbase",$LDAPBaseDN)
        }
        if (-not [string]::IsNullOrEmpty($LDAPBindDN)) 
        {
           $payload.Add("ldapbinddn",$LDAPBindDN)
        }
        if (-not [string]::IsNullOrEmpty($LDAPBindDN)) 
        {
           $payload.Add("ldapbinddnpassword",$LDAPBindDNPassword)
        }
        if (-not [string]::IsNullOrEmpty($LDAPLoginName)) 
        {
           $payload.Add("ldaploginname",$LDAPLoginName)
        }
      
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType authenticationldapaction -ResourceName $LDAPActionName -Payload $payload -Verbose:$VerbosePreference  

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
