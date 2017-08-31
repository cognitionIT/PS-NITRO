    function Remove-NSCSAction {
            <#
            .SYNOPSIS
                Remove a NetScaler CS Action from the NetScalerConfiguration
            .DESCRIPTION
                Remove a NetScaler Content Switching Action from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the CS Action.
            .EXAMPLE
                Remove-NSCSAction -NSSession $Session -Name cs_act_unifiedgateway
            .NOTES
                Version:        1.0
                Author:         Esther Barthel, MSc
                Creation Date:  2017-08-30

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
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType csaction -ResourceName $Name -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
