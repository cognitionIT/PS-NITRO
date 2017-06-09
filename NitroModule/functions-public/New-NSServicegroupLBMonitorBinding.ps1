        # Created: 20160825
        function New-NSServicegroupLBMonitorBinding {
            <#
            .SYNOPSIS
                Bind monitor to servicegroup
            .DESCRIPTION
                Bind monitor to servicegroup
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER ServicegroupName
                Name of the servicegroup to which to bind monitor
            .PARAMETER MonitorName
                The monitor name
            .EXAMPLE
                New-NSServicegroupLBMonitorBinding -NSSession $Session -ServicegroupName svcgrp_lb_storefront -MonitorName mon_storefront
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
