    function Get-NSCSAction {
        <#
        .SYNOPSIS
            Retrieve NetScaler CS action information
        .DESCRIPTION
            Retrieve NetScaler CS action information
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the CS action to retrieve.
        .EXAMPLE
            Get-NSCSAction -NSSession $Session -Name cs_act_unifiedgateway
        .NOTES
            Version:        1.0
            Author:         Esther Barthel, MSc
            Creation Date:  2017-08-30

            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$Name
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($Name){
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType csaction -ResourceName $Name
            }
            Else {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType csaction
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['csaction'])
            {
                return $response.csaction
            }
            else
            {
                return $null
            }
        }
    }
