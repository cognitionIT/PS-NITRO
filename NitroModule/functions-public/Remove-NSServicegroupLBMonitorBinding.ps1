        function Remove-NSServicegroupLBMonitorBinding{
        # Created: 20160825
            <#
            .SYNOPSIS
                Remove a NetScaler Monitor Binding from a Servicegroup
            .DESCRIPTION
                Remove a NetScaler Monitor Binding from a Servicegroup
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER ServicegroupName
                Name of the servicegroup.
            .PARAMETER MonitorName
                Name of the monitor bound to the servicegroup.
            .EXAMPLE
                Remove-NSServicegroupLBMonitorBinding -NSSession $Session -ServicegroupName $ServicegroupName -MonitorName $MonitorName
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$ServicegroupName,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$MonitorName
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
                $args=@{monitor_name=$MonitorName}
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType servicegroup_lbmonitor_binding -ResourceName $ServicegroupName -Arguments $args -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
