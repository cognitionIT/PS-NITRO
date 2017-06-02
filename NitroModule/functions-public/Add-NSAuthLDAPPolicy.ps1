    # Add-NSAuthLDAPPolicy is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    function Add-NSAuthLDAPPolicy {
        <#
        .SYNOPSIS
            Add a new NetScaler LDAP policy
        .DESCRIPTION
            Add a new NetScaler LDAP policy
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Action
            Name of the LDAP action to perform if the policy matches.
        .PARAMETER Name
            Name of the LDAP policy
        .PARAMETER RuleExpression
            Name of the NetScaler named rule, or a default syntax expression, that the policy uses to determine whether to attempt to authenticate the user with the LDAP server.
        .EXAMPLE
            Add-NSAuthLDAPPolicy -NSSession $Session -LDAPActionName "10.8.115.245_LDAP" -LDAPPolicyName "10.8.115.245_LDAP_pol" -LDAPRuleExpression NS_TRUE
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$Action,
            [Parameter(Mandatory=$true)] [string]$Name,
            [Parameter(Mandatory=$false)] [string]$RuleExpression="ns_true"
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload = @{reqaction=$Action;name=$Name;rule=$RuleExpression}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType authenticationldappolicy -Payload $payload  

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
