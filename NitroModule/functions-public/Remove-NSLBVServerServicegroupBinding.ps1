    function Remove-NSLBVServerServicegroupBinding {
            <#
            .SYNOPSIS
                Remove a NetScaler Servicegroup binding to a vServer from the NetScalerConfiguration
            .DESCRIPTION
                Remove a NetScaler Servicegroup binding to a vServer from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the vServer.
            .PARAMETER ServiceGroupName
                Name of the Servicegroup bound to the vServer
            .EXAMPLE
                Remove-NSLBVServerServicegroupBinding -NSSession $NSSession -Name vsvr_lb_storefront -ServiceGroupName svcgrp_storefront
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$Name,
            # The service group name bound to the selected load balancing virtual server
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$ServiceGroupName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $args=@{name=$Name;servicegroupname=$ServiceGroupName}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType lbvserver_servicegroup_binding -ResourceName $Name -Arguments $args -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
