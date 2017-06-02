    function Show-NSAuthLDAPPolicyBindings {
        <#
        .SYNOPSIS
            Retrieve resources that can be bound to the given LDAPPolicy
        .DESCRIPTION
            Retrieve resources that can be bound to the given LDAPPolicy
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER PolicyName
            Name of the LDAP policy
        .EXAMPLE
            Get-NSAuthLDAPPolicyBinding -NSSession $Session -LDAPPolicyName $PolicyName
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$PolicyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType authenticationldappolicy_binding -ResourceName $PolicyName -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['authenticationldappolicy_binding'])
        {
            return $response.authenticationldappolicy_binding
        }
        else
        {
            return $null
        }
    }
