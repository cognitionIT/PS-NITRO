    # Set-NSTimeZone is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    # Updated 20160809: Removed Action parameter from Invoke-NSNitroRestApi call
    function Set-NSTimeZone {
        <#
        .SYNOPSIS
            Set NetScaler Appliance Timezone
        .DESCRIPTION
            Set NetScaler Appliance Timezone
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER TimeZone
            Valid NetScaler specific name of the timezone. e.g. "GMT-05:00-EST-America/Panama"
            For more information on valid names run Import-NSTimeZones which returns a list of all timezones.
        .EXAMPLE
             Set-NSTimeZone -NSSession $Session -TimeZone "GMT-05:00-EST-America/Panama"
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [ValidateScript({
                if ($NSTimeZones -contains $_) {
                    $true
                } else {
                    throw "Valid values are: $($NSTimeZones -join ', ')"
                }
            })] [string]$TimeZone
        )
    
        Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
        $payload = @{timezone=$TimeZone}
        $Job = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType nsconfig -Payload $payload 

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
