    # Updated: 20160824 - Removed unknown Action parameter
    function New-NSLBVServerServicegroupBinding {
        <#
        .SYNOPSIS
            Bind a Servicegroup to a Load Balancing vServer
        .DESCRIPTION
            Bind a Servicegroup to a Load Balancing vServer
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the virtual server
        .PARAMETER ServiceGroupName
            Servicegroup to bind to the vServer
        .EXAMPLE
            New-NSLBVServerServicegroupBinding -NSSession $Session -Name vsvr_lb_storefront -ServiceGroupName svcgrp_lb_storefront
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            # Name for the virtual server.
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            # The service group name bound to the selected load balancing virtual server
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$ServiceGroupName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name}
        }
        Process {
            if (-not [string]::IsNullOrEmpty($ServiceGroupName)) {$payload.Add("servicegroupname",$ServiceGroupName)}
#            if (-not [string]::IsNullOrEmpty($ServiceName)) {$payload.Add("servicename",$ServiceName)}
#            if ($Weight) {$payload.Add("weight",$Weight)}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType lbvserver_servicegroup_binding -Payload $payload
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
