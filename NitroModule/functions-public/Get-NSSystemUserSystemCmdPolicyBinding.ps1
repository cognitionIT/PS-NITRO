    function Get-NSSystemUserSystemCmdPolicyBinding {
        <#
        .SYNOPSIS
            Get the bound command policy(s) to a given system user of the NetScaler Configuration
        .DESCRIPTION
            Get the bound command policy(s) to a given system user of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name of the user to retrieve the binding from. Minimum length = 1
        .EXAMPLE
            Get-NSSystemUserSystemCmdPolicyBinding -NSSession $Session -UserName user -PolicyName commandpolicy
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$UserName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemuser_systemcmdpolicy_binding -ResourceName $UserName -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['systemuser_systemcmdpolicy_binding'])
        {
            return $response.systemuser_systemcmdpolicy_binding
        }
        else
        {
            return $null
        }
    }
