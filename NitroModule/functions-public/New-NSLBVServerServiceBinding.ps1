    # New-NSLBVServerServiceBinding is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    # CHANGED
    function New-NSLBVServerServiceBinding {
    # Updated: 20160824 - Removed unknown Action parameter
        <#
        .SYNOPSIS
            Bind service to VPN virtual server
        .DESCRIPTION
            Bind service to VPN virtual server
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER VirtualServerName
            Name of the virtual server
        .PARAMETER ServiceName
            Service to bind to the virtual server
        .EXAMPLE
            New-NSLBVServerServiceBinding -NSSession $Session -VirtualServerName "myLBVirtualServer" -ServiceName "Server1_Service"
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            # Name for the virtual server.
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            # Service to bind to the virtual server.
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$ServiceName,
            # Integer specifying the weight of the service. Default value: 1. Minimum value = 1. Maximum value = 100
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
