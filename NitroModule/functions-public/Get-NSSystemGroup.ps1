    function Get-NSSystemGroup {
        <#
        .SYNOPSIS
            Retrieve system group resource(s) from the NetScaler configuration
        .DESCRIPTION
            Retrieve system group resource(s) from the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSystemGroup -NSSession $Session -GroupName group
        .EXAMPLE
            Get-NSSystemGroup -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$GroupName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{}

        If (-not [string]::IsNullOrEmpty($GroupName)) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemgroup -ResourceName $GroupName
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemgroup
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['systemgroup'])
        {
            return $response.systemgroup
        }
        else
        {
            return $null
        }
    }
