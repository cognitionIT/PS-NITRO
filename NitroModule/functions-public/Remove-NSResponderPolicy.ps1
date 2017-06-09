    function Remove-NSResponderPolicy {
        <#
        .SYNOPSIS
            Remove a Responder Policy from the NetScalerConfiguration
        .DESCRIPTION
            Remove a Responder Policy from the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name for the user-defined responder policy.
        .EXAMPLE
            Remove-NSResponderPolicy -NSSession $Session -Name rsp_pol_http_https_redirect
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$Name
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType responderpolicy -ResourceName $Name
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
