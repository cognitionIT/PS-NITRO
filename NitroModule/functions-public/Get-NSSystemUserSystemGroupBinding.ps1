    function Get-NSSystemUserSystemGroupBinding {
        <#
        .SYNOPSIS
            Retrieve the binded system group(s) for a given system user of the NetScaler Configuration
        .DESCRIPTION
            Retrieve the binded system group(s) for a given system user of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name of the user to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSystemUserSystemGroupBinding -NSSession $Session -Group group
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$UserName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{}

        If (-not [string]::IsNullOrEmpty($UserName)) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemuser_systemgroup_binding -ResourceName $UserName
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemuser_systemgroup_binding
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['systemuser_systemgroup_binding'])
        {
            return $response.systemuser_systemgroup_binding
        }
        else
        {
            return $null
        }
    }
