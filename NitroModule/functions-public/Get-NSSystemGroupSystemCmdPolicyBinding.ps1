    function Get-NSSystemGroupSystemCmdPolicyBinding {
        <#
        .SYNOPSIS
            Get the bound command policy(s) to a given system group of the NetScaler Configuration
        .DESCRIPTION
            Get the bound command policy(s) to a given system group of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to add the binding to. Minimum length = 1
        .EXAMPLE
            Remove-NSSystemGroupSystemCmdPolicyBinding -NSSession $Session -GroupName group -PolicyName commandpolicy
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemgroup_systemcmdpolicy_binding -ResourceName $GroupName

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['systemgroup_systemcmdpolicy_binding'])
        {
            return $response.systemgroup_systemcmdpolicy_binding
        }
        else
        {
            return $null
        }
    }
