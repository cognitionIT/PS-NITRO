        function Get-NSServiceGroup {
            <#
            .SYNOPSIS
                Retrieve a Service from the NetScalerConfiguration
            .DESCRIPTION
                Retrieve a Service from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name for the service. Can be changed after the name is created. Minimum length = 1.
            .EXAMPLE
                Get-NSService -NSSession $Session -Name $ServiceName
            .EXAMPLE
                Get-NSService -NSSession $Session
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
                    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType servicegroup -ResourceName $Name -Verbose:$VerbosePreference
                }
                Else {
                    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType servicegroup
                }
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
                If ($response.PSObject.Properties['servicegroup'])
                {
                    return $response.servicegroup
                }
                else
                {
                    return $null
                }
            }
        }
