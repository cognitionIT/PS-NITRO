    function Get-NSMode {
        <#
        .SYNOPSIS
            Get (all) NetScaler appliance mode(s)
        .DESCRIPTION
            Get one or more NetScaler appliance mode(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Mode
            Mode to be retrieved.
        .EXAMPLE
            Get-NSMode -NSSession $Session -Mode "wl"
        .EXAMPLE
            Get-NSMode -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string[]]$Mode
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        If ($Mode) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsmode -ResourceName $Mode -Verbose:$VerbosePreference
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsmode -Verbose:$VerbosePreference
        }

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['nsmode'])
        {
            return $response.nsmode
        }
        else
        {
            return $null
        }
    }
