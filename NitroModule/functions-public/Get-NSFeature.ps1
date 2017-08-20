    function Get-NSFeature {
        <#
        .SYNOPSIS
            Get (all) NetScaler appliance feature(s)
        .DESCRIPTION
            Get one or more NetScaler appliance feature(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Feature
            Feature to be retrieved.
        .EXAMPLE
            Get-NSFeature -NSSession $Session -Feature "sslvpn"
        .EXAMPLE
            Get-NSFeature -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string[]]$Feature
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        If ($Feature) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsfeature -ResourceName $Feature -Verbose:$VerbosePreference
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsfeature -Verbose:$VerbosePreference
        }

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['nsfeature'])
        {
            return $response.nsfeature
        }
        else
        {
            return $null
        }
    }
