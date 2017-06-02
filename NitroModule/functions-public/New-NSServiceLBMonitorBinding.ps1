        # New-NSServiceLBMonitorBinding is part of the Citrix NITRO Module
        # Copied from Citrix's Module to ensure correct scoping of variables and functions
        function New-NSServiceLBMonitorBinding {
            <#
            .SYNOPSIS
                Bind monitor to service
            .DESCRIPTION
                Bind monitor to service
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER ServiceName
                Name of the service to which to bind monitor
            .PARAMETER MonitorName
                The monitor name
            .EXAMPLE
                New-NSServiceLBMonitorBinding -NSSession $Session -ServiceName "Server1_Service" -MonitorName "Server1_Monitor"
            .NOTES
                Copyright (c) Citrix Systems, Inc. All rights reserved.
            #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$ServiceName,
                [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$MonitorName,
                [Parameter(Mandatory=$false)] [string]$State,
                [Parameter(Mandatory=$false)] [int]$Weight,
                [Parameter(Mandatory=$false)] [switch]$Passive
            )

            Write-Verbose "$($MyInvocation.MyCommand): Enter"

            $payload = @{name=$ServiceName;monitor_name=$MonitorName}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType service_lbmonitor_binding -Payload $payload -Verbose:$VerbosePreference 

            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
