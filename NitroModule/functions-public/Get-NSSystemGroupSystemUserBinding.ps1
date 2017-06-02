    function Get-NSSystemGroupSystemUserBinding {
        <#
        .SYNOPSIS
            Retrieve the binded system user(s) for a given system group of the NetScaler Configuration
        .DESCRIPTION
            Retrieve the binded system user(s) for a given system group of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSystemGroupSystemUserBinding -NSSession $Session -Group group
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{}

        If (-not [string]::IsNullOrEmpty($GroupName)) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemgroup_systemuser_binding -ResourceName $GroupName
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemgroup_systemuser_binding
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['systemgroup_systemuser_binding'])
        {
            return $response.systemgroup_systemuser_binding
        }
        else
        {
            return $null
        }
    }
