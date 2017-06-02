    function Update-NSAuthLDAPPolicy {
        <#
        .SYNOPSIS
            Update a NetScaler LDAP policy
        .DESCRIPTION
            Update a NetScaler LDAP policy
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the LDAP policy
        .PARAMETER RuleExpression
            Name of the NetScaler named rule, or a default syntax expression, that the policy uses to determine whether to attempt to authenticate the user with the LDAP server.
        .PARAMETER Action
            Name of the LDAP action to perform if the policy matches.
        .EXAMPLE
            Update-NSAuthLDAPPolicy -NSSession $Session -LDAPPolicyName "10.8.115.245_LDAP_pol" -LDAPRuleExpression NS_TRUE -LDAPActionName "10.8.115.245_LDAP" 
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$RuleExpression="ns_true",
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Action
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload = @{name=$Name;rule=$RuleExpression;reqaction=$Action}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType authenticationldappolicy -Payload $payload -Verbose:$VerbosePreference  

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
