    function Get-NSRewritePolicy {
        <#
        .SYNOPSIS
            Retrieve a Rewrite Policy to the NetScalerConfiguration
        .DESCRIPTION
            Retrieve a Rewrite Policy to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER PolicyName
            Name for the rewrite policy.
        .PARAMETER ShowBuiltIn
            Include default rewritepolicies in results.
        .EXAMPLE
            Get-NSRewritePolicy -NSSession $Session -PolicyName $PolicyName
        .EXAMPLE
            Get-NSRewritePolicy -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]  [string]$PolicyName,
            [Parameter(Mandatory=$false)] [switch]$ShowBuiltIn
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($PolicyName) {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType rewritepolicy -ResourceName $PolicyName
            }
            Else
            {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType rewritepolicy
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['rewritepolicy'])
            {
                If ($ShowBuiltIn)
                {
                    return $response.rewritepolicy
                }
                Else
                {
                    return $response.rewritepolicy | Where-Object {$_.isdefault -eq $false}
                }
            }
            else
            {
                return $null
            }
        }
    }
