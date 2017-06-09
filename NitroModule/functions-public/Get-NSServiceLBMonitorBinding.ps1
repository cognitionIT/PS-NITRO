        # Created: 20160825
        function Get-NSServiceLBMonitorBinding{
            <#
            .SYNOPSIS
                Retrieve a Monitor binding for a given Service
            .DESCRIPTION
                Retrieve a Monitor binding for a given Service
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the service
            .EXAMPLE
                Get-NSServiceLBMonitorBinding -NSSession $Session -Name $ServiceName
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType service_lbmonitor_binding -ResourceName $Name -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
                If ($response.PSObject.Properties['service_lbmonitor_binding'])
                {
                    return $response.service_lbmonitor_binding
                }
                else
                {
                    return $null
                }
            }
        }
