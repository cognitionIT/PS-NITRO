        # Created: 20160825
        function Get-NSServicegroupLBMonitorBinding{
            <#
            .SYNOPSIS
                Retrieve a Monitor binding for a given Servicegroup
            .DESCRIPTION
                Retrieve a Monitor binding for a given Servicegroup
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the service
            .EXAMPLE
                Get-NSServicegroupLBMonitorBinding -NSSession $Session -Name $Name
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
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType servicegroup_lbmonitor_binding -ResourceName $Name -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
                If ($response.PSObject.Properties['servicegroup_lbmonitor_binding'])
                {
                    return $response.servicegroup_lbmonitor_binding
                }
                else
                {
                    return $null
                }
            }
        }
