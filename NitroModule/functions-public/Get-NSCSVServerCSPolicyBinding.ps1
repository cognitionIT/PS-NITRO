    function Get-NSCSVServerCSPolicyBinding {
        <#
        .SYNOPSIS
            Retrieve NetScaler CS policy binding information
        .DESCRIPTION
            Retrieve NetScaler CS policy binding information
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the CS policy to retrieve.
        .EXAMPLE
            Get-NSCVServerCSPolicyBinding -NSSession $Session -Name cs_pol_unifiedgateway
        .NOTES
            Version:        1.0
            Author:         Esther Barthel, MSc
            Creation Date:  2017-09-13

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
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType csvserver_cspolicy_binding -ResourceName $Name
            }
            Else {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType csvserver_cspolicy_binding
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['csvserver_cspolicy_binding'])
            {
                return $response.csvserver_cspolicy_binding
            }
            else
            {
                return $null
            }
        }
    }
