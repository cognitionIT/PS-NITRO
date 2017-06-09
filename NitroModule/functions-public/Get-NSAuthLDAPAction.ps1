    function Get-NSAuthLDAPAction {
        <#
        .SYNOPSIS
            Retrieve a NetScaler LDAP action
        .DESCRIPTION
            Retrieve a NetScaler LDAP action
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER LDAPActionName
            Name of the LDAP action. 
        .EXAMPLE
            Get-NSAuthLDAPAction -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$LDAPActionName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        If ([string]::IsNullOrEmpty($LDAPActionName))
        {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType authenticationldapaction 
        }
        Else
        {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType authenticationldapaction -ResourceName $LDAPActionName 
        }


        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['authenticationldapaction'])
        {
            return $response.authenticationldapaction
        }
        else
        {
            return $null
        }
    }
