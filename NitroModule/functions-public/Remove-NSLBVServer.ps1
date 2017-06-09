    function Remove-NSLBVServer {
            <#
            .SYNOPSIS
                Remove a NetScaler Load Balancing vServer from the NetScalerConfiguration
            .DESCRIPTION
                Remove a NetScaler Load Balancing vServer from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the vServer.
            .EXAMPLE
                Remove-NSLBVServer -NSSession $Session -Name vsvr_lb_storefront
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$Name
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType lbvserver -ResourceName $Name -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
