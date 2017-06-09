    function Remove-NSLBVServerServiceBinding {
            <#
            .SYNOPSIS
                Remove a NetScaler Service binding to a vServer from the NetScalerConfiguration
            .DESCRIPTION
                Remove a NetScaler Service binding to a vServer from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the vServer.
            .PARAMETER ServiceName
                Name of the Service bound to the vServer
            .EXAMPLE
                Remove-NSLBVServerServiceBinding -NSSession $NSSession -Name vsvr_lb_storefront -ServiceName svc_storefront
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$Name,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$ServiceName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $args=@{name=$Name;servicename=$ServiceName}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType lbvserver_service_binding -ResourceName $Name -Arguments $args -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
