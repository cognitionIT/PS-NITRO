    function Get-NSResponderAction {
        <#
        .SYNOPSIS
            Retrieve a Responder Action to the NetScalerConfiguration
        .DESCRIPTION
            Retrieve a Responder Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined rewrite action.
        .EXAMPLE
            Get-NSResponderAction -NSSession $Session -ActionName $ActionName
        .EXAMPLE
            Get-NSResponderAction -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]  [string]$ActionName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($ActionName) {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType responderaction -ResourceName $ActionName
            }
            Else
            {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType responderaction
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['responderaction'])
            {
                return $response.responderaction
            }
            else
            {
                return $null
            }
        }
    }
