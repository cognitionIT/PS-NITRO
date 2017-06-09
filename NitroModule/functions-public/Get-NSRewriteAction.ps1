    function Get-NSRewriteAction {
        <#
        .SYNOPSIS
            Retrieve the Rewrite Action from the NetScaler Configuration
        .DESCRIPTION
            Retrieve the Rewrite Action from the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined rewrite action.
        .PARAMETER ShowBuiltIn
            Switch parameter
            Flag to determine if rewrite policy is built-in or not. 
            Possible values = MODIFIABLE, DELETABLE, IMMUTABLE, PARTITION_ALL
        .EXAMPLE
            Get-NSRewriteAction -NSSession $Session -ActionName rw_act_default_store
        .EXAMPLE
            Get-NSRewriteAction -NSSession $Session -ShowBuiltIn
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
