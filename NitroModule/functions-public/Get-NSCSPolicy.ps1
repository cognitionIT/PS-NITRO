    function Get-NSCSPolicy {
        <#
        .SYNOPSIS
            Retrieve NetScaler CS policy information
        .DESCRIPTION
            Retrieve NetScaler CS policy information
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the CS policy to retrieve.
        .EXAMPLE
            Get-NSCSPolicy -NSSession $Session -Name cs_pol_unifiedgateway
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
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType cspolicy -ResourceName $Name
            }
            Else {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType cspolicy
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['cspolicy'])
            {
                return $response.cspolicy
            }
            else
            {
                return $null
            }
        }
    }
