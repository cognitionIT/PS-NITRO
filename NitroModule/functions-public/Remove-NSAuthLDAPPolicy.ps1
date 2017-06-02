    function Remove-NSAuthLDAPPolicy {
        <#
        .SYNOPSIS
            Remove a NetScaler LDAP policy
        .DESCRIPTION
            Remove a NetScaler LDAP policy
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the LDAP policy to remove.
        .EXAMPLE
            Remove-NSAuthLDAPPolicy -NSSession $Session -LDAPPolicyName "10.8.115.245_pol"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType authenticationldappolicy -ResourceName $Name -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
