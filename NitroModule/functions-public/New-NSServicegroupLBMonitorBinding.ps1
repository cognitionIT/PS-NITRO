        function New-NSServicegroupLBMonitorBinding {
        # Created: 20160825
            <#
            .SYNOPSIS
                Bind monitor to servicegroup
            .DESCRIPTION
                Bind monitor to servicegroup
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER ServiceName
                Name of the servicegroup to which to bind monitor
            .PARAMETER MonitorName
                The monitor name
            .EXAMPLE
                New-NSServicegroupLBMonitorBinding -NSSession $Session -ServicegroupName "Server1_Service" -MonitorName "Server1_Monitor"
            .NOTES
                Copyright (c) Citrix Systems, Inc. All rights reserved.
            #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)] [string]$ServicegroupName,
                [Parameter(Mandatory=$true)] [string]$MonitorName
            )

            Write-Verbose "$($MyInvocation.MyCommand): Enter"

            $payload = @{servicegroupname=$ServicegroupName;monitor_name=$MonitorName}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType servicegroup_lbmonitor_binding -Payload $payload -Verbose:$VerbosePreference 

            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
