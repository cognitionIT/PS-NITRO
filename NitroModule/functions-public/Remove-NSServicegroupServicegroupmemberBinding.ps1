        function Remove-NSServicegroupServicegroupmemberBinding {
            <#
            .SYNOPSIS
                Remove a NetScaler ServiceGroup from the NetScalerConfiguration
            .DESCRIPTION
                Remove a NetScaler ServiceGroup from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the Servicegroup.
            .PARAMETER ServerName
                Name of the Server to unbind from the service group
            .PARAMETER IPAddress
                IP Address.
            .PARAMETER Port
                Server port number.
            .EXAMPLE
                Remove-NSServicegroupServicegroupmemberBinding -NSSession $Session -Name svcgrp_lb_storefront -ServerName SF1
            .EXAMPLE
                Remove-NSServicegroupServicegroupmemberBinding -NSSession $Session -Name svcgrp_lb_storefront -IPAddress "192.168.0.21"
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
                [Parameter(Mandatory=$true,ParameterSetName='By Name')] [string]$ServerName,
                [Parameter(Mandatory=$true,ParameterSetName='By Address')] [string]$IPAddress,
                [Parameter(Mandatory=$false)] [ValidateRange(1,65535)] [int]$Port
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"

                $args = @{port=$Port}
                if ($PSCmdlet.ParameterSetName -eq 'By Name') {
                    $args.Add("servername",$ServerName)
                } elseif ($PSCmdlet.ParameterSetName -eq 'By Address') {
                    Write-Verbose "Validating IP Address"
                    $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                    if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj)) {
                        throw "'$IPAddress' is an invalid IP address"
                    }
                    $args.Add("ip",$IPAddress)
                }
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType servicegroup_servicegroupmember_binding -ResourceName $Name -Arguments $args -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
