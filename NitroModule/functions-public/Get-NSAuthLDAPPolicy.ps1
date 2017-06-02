    function Get-NSAuthLDAPPolicy {
        <#
        .SYNOPSIS
            Retrieve all NetScaler LDAP policies
        .DESCRIPTION
            Retrieve all NetScaler LDAP policies
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the LDAP policy
        .EXAMPLE
            Get-NSAuthLDAPPolicy -NSSession $Session
        .EXAMPLE
            Get-NSAuthLDAPPolicy -NSSession $Session -LDAPPolicyName $PolicyName
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$Name
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"
        If ([string]::IsNullOrEmpty($Name))
        {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType authenticationldappolicy
        }
        Else
        {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType authenticationldappolicy -ResourceName $Name
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['authenticationldappolicy'])
        {
            return $response.authenticationldappolicy
        }
        else
        {
            return $null
        }
    }
