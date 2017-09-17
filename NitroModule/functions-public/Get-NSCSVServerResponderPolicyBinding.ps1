    function Get-NSCSVServerResponderPolicyBinding {
        <#
        .SYNOPSIS
            Retrieve NetScaler Responder policy binding information for a CS vServer
        .DESCRIPTION
            Retrieve NetScaler Responder policy binding information for a CS vServer
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the Responder policy to retrieve.
        .EXAMPLE
            Get-NSCVServerCSPolicyBinding -NSSession $Session -Name "cs_vsvr_http_https_redirection"
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
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType csvserver_responderpolicy_binding -ResourceName $Name
            }
            Else {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType csvserver_responderpolicy_binding
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['csvserver_responderpolicy_binding'])
            {
                return $response.csvserver_responderpolicy_binding
            }
            else
            {
                return $null
            }
        }
    }
