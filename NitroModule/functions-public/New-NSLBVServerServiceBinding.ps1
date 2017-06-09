    # New-NSLBVServerServiceBinding is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    # CHANGED
    # Updated: 20160824 - Removed unknown Action parameter
    function New-NSLBVServerServiceBinding {
        <#
        .SYNOPSIS
            Bind a Service to a Load Balancing vServer
        .DESCRIPTION
            Bind a Service to a Load Balancing vServer
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the virtual server
        .PARAMETER ServiceName
            Service to bind to the virtual server
        .PARAMETER Weight
            Integer specifying the weight of the service. Default value: 1. Minimum value = 1. Maximum value = 100
        .EXAMPLE
            New-NSLBVServerServiceBinding -NSSession $Session -Name vsvr_lb_storefront -ServiceName svc_lb_storefront
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$ServiceName,
            [Parameter(Mandatory=$false)][ValidateRange(1,100)] [int]$Weight
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name}
        }
        Process {
            if (-not [string]::IsNullOrEmpty($ServiceName)) {$payload.Add("servicename",$ServiceName)}
            if ($Weight) {$payload.Add("weight",$Weight)}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType lbvserver_servicegroup_binding -Payload $payload
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
