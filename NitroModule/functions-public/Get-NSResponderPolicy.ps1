    function Get-NSResponderPolicy {
        <#
        .SYNOPSIS
            Retrieve Responder Policy information from the NetScaler
        .DESCRIPTION
            Retrieve Responder Policy information from the NetScaler
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the responder policy.
        .PARAMETER ShowBuiltIn
            Switch parameter
            Flag to determine if responder policy is built-in or not. 
            Possible values = MODIFIABLE, DELETABLE, IMMUTABLE, PARTITION_ALL
        .EXAMPLE
            Get-NSResponderPolicy -NSSession $Session -Name rsp_pol_http_https_redirect
        .EXAMPLE
            Get-NSResponderPolicy -NSSession $Session -ShowBuiltIn
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]  [string]$Name,
            [Parameter(Mandatory=$false)] [switch]$ShowBuiltIn
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($Name) {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType responderpolicy -ResourceName $Name -Verbose
            }
            Else
            {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType responderpolicy
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['responderpolicy'])
            {
                If ($ShowBuiltIn)
                {
                    return $response.responderpolicy
                }
                Else
                {
                    # The builtin property is not set for user created policies. Only select objects that do not have the builtin property.
                    return $response.responderpolicy | Where-Object {!($_.PSObject.Properties['builtin'])} -ErrorAction SilentlyContinue
                }
            }
            else
            {
                return $null
            }
        }
    }
