    function Remove-NSAuthLDAPAction {
        <#
        .SYNOPSIS
            Remove a NetScaler LDAP action
        .DESCRIPTION
            Remove a NetScaler LDAP action
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER LDAPActionName
            Name of the LDAP action
        .EXAMPLE
            Remove-NSAuthLDAPAction -NSSession $Session -LDAPActionName "10.108.151.1_LDAP"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$LDAPActionName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType authenticationldapaction -ResourceName $LDAPActionName 

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
