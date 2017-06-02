    # Enable-NSMode is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    function Enable-NSMode {
        <#
        .SYNOPSIS
            Enable NetScaler appliance mode(s)
        .DESCRIPTION
            Enable one or more NetScaler appliance mode(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Mode
            Mode(s) to be enabled. This can be passed as multiple modes (comma or space separated).
        .EXAMPLE
            Enable-NSMode -NSSession $Session -Mode "usnip"
        .EXAMPLE
            Enable-NSMode -NSSession $Session -Mode "usnip","mbf"
        .EXAMPLE
            Enable-NSMode -NSSession $Session -Mode "usnip mbf"
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string[]]$Mode
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $modeParsed = $Mode.Trim().ToUpper() -join ' '

        $payload = @{mode=$modeParsed}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsmode -Payload $payload -Action enable -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
