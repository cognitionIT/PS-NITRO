        function Get-NSServiceGroupBinding {
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
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType servicegroup_binding -ResourceName $Name -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
                If ($response.PSObject.Properties['servicegroup_binding'])
                {
                    return $response.servicegroup_binding
                }
                else
                {
                    return $null
                }
            }
        }
