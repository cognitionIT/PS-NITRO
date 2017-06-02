    function Remove-NSRewritePolicy {
        <#
        .SYNOPSIS
            Remove a Rewrite Policy to the NetScalerConfiguration
        .DESCRIPTION
            remove a Rewrite Policy to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER PolicyName
            Name for the rewrite policy.
        .EXAMPLE
            Remove-NSRewritePolicy -NSSession $Session -PolicyName $PolicyName
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$PolicyName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType rewritepolicy -ResourceName $PolicyName
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
