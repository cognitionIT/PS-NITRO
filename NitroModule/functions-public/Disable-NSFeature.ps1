    function Disable-NSFeature {
        <#
        .SYNOPSIS
            Disable NetScaler appliance feature(s)
        .DESCRIPTION
            Disable one or more NetScaler appliance feature(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Feature
            Feature(s) to be disabled. This can be passed as multiple features (comma or space separated).
        .EXAMPLE
            Disable-NSFeature -NSSession $Session -Feature "sslvpn"
        .EXAMPLE
            Disable-NSFeature -NSSession $Session -Feature "sslvpn","lb"
        .EXAMPLE
            Disable-NSFeature -NSSession $Session -Feature "sslvpn lb"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string[]]$Feature
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $featureParsed = $Feature.Trim().ToUpper() -join ' '

        $payload = @{feature=$featureParsed}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsfeature -Payload $payload -Action disable -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
