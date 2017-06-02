        function Get-NSServer {
            <#
            .SYNOPSIS
                Retrieve a Server from the NetScalerConfiguration
            .DESCRIPTION
                Retrieve a Server from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name for the server. Can be changed after the name is created. Minimum length = 1.
            .PARAMETER Name
                Name of the server. Can be changed after the name is created. Minimum length = 1.
            .EXAMPLE
                Get-NSServer -NSSession $Session -Name $ServerName
            .EXAMPLE
                Get-NSServer -NSSession $Session
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
            }
            Process {
                If ($Name) {
                    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType server -ResourceName $Name -Verbose
                }
                Else
                {
                    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType server
                }
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
                If ($response.PSObject.Properties['server'])
                {
                    return $response.server
                }
                else
                {
                    return $null
                }
            }

        }
