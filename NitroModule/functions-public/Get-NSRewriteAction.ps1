    function Get-NSRewriteAction {
        <#
        .SYNOPSIS
            Retrieve a Rewrite Action to the NetScalerConfiguration
        .DESCRIPTION
            Retrieve a Rewrite Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined rewrite action.
        .EXAMPLE
            Get-NSRewriteAction -NSSession $Session -ActionName $ActionName
        .EXAMPLE
            Get-NSRewriteAction -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]  [string]$ActionName,
            [Parameter(Mandatory=$false)] [switch]$ShowBuiltIn
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($ActionName) {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType rewriteaction -ResourceName $ActionName
            }
            Else
            {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType rewriteaction
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['rewriteaction'])
            {
                If ($ShowBuiltIn)
                {
                    return $response.rewriteaction
                }
                Else
                {
                    return $response.rewriteaction | Where-Object {$_.isdefault -eq $false}
                }
            }
            else
            {
                return $null
            }
        }
    }
