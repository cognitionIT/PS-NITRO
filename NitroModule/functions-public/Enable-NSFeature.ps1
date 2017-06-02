    # Enable-NSFeature is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    function Enable-NSFeature {
        <#
        .SYNOPSIS
            Enable NetScaler appliance feature(s)
        .DESCRIPTION
            Enable one or more NetScaler appliance feature(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Feature
            Feature(s) to be enabled. This can be passed as multiple features (comma or space separated).
        .EXAMPLE
            Enable-NSFeature -NSSession $Session -Feature "sslvpn"
        .EXAMPLE
            Enable-NSFeature -NSSession $Session -Feature "sslvpn","lb"
        .EXAMPLE
            Enable-NSFeature -NSSession $Session -Feature "sslvpn lb"
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string[]]$Feature
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $featureParsed = $Feature.Trim().ToUpper() -join ' '

        $payload = @{feature=$featureParsed}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsfeature -Payload $payload -Action enable -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
