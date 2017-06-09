        function Disable-NSServiceGroup {
        <#
        .SYNOPSIS
            Disable NetScaler ServiceGroup
        .DESCRIPTION
            Disable NetScaler ServiceGroup
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the ServiceGroup to be disabled.
        .PARAMETER Graceful
            Switch parameter
            Shut down gracefully, not accepting any new connections, and disabling the service when all of its connections are closed.
            Default value: NO
            Possible values = YES, NO
        .PARAMETER Delay
            Time, in seconds, allocated to the NetScaler appliance for a graceful shutdown of the service.
        .EXAMPLE
            Disable-NSServiceGroup -NSSession $Session -Name svc_lb_storefront -Graceful
        .EXAMPLE
            Disable-NSServiceGroup -NSSession $Session -Name svc_lb_storefront -Delay 5
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
                [Parameter(Mandatory=$false)][int]$Delay,
                [Parameter(Mandatory=$false)] [switch]$Graceful
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
                $GracefulState = if ($Graceful) { "YES" } else { "NO" }

                $payload = @{servicegroupname=$Name;graceful=$GracefulState}
                If ($Delay)
                {
                    $payload.Add("delay", $Delay)
                }
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType servicegroup -Payload $payload -Verbose:$VerbosePreference -Action disable
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
