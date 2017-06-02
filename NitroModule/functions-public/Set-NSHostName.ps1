    # Set-NSHostName is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    # Updated 20160809: Removed action parameter from Invoke-NSNitroRestApi call
    function Set-NSHostName {
        <#
        .SYNOPSIS
            Set NetScaler Appliance Hostname
        .DESCRIPTION
            Set NetScaler Appliance Hostname
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER HostName
            Host name for the NetScaler appliance
        .EXAMPLE
             Set-NSHostName -NSSession $Session -HostName "sslvpn-sg"
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$HostName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload = @{hostname=$HostName}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType nshostname -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
