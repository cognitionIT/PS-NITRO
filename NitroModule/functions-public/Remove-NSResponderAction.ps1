    function Remove-NSResponderAction {
        <#
        .SYNOPSIS
            Remove a Rewrite Action to the NetScalerConfiguration
        .DESCRIPTION
            Remove a Rewrite Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined rewrite action.
        .EXAMPLE
            Remove-NSRewriteAction -NSSession $Session -ActionName $ActionName
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$ActionName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType responderaction -ResourceName $ActionName
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
