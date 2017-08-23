    function Remove-NSCSVServer {
            <#
            .SYNOPSIS
                Remove a NetScaler CS vServer from the NetScalerConfiguration
            .DESCRIPTION
                Remove a NetScaler Content Switching vServer from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the vServer.
            .EXAMPLE
                Remove-NSCSVServer -NSSession $Session -Name cs_vsvr_unifiedgateway
            .NOTES
                Version:        1.0
                Author:         Esther Barthel, MSc
                Creation Date:  2017-08-21

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
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType csvserver -ResourceName $Name -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
