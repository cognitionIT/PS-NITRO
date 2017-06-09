    # SOLVED: Disable-NSService renders the NetScaler unresponsive (stupid me bound the service to localhost on HTTP 80 (same as REST Web services) DOH!)
        function Disable-NSService {
        <#
        .SYNOPSIS
            Disable NetScaler Service
        .DESCRIPTION
            Disable NetScaler Service
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the Service to be disabled.
        .PARAMETER Graceful
            Switch parameter
            Shut down gracefully, not accepting any new connections, and disabling the service when all of its connections are closed.
            Default value: NO
            Possible values = YES, NO
        .PARAMETER Delay
            Time, in seconds, allocated to the NetScaler appliance for a graceful shutdown of the service.
        .EXAMPLE
            Disable-NSService -NSSession $Session -Name svc_lb_storefront -Graceful
        .EXAMPLE
            Disable-NSService -NSSession $Session -Name svc_lb_storefront -Delay 5
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
                [Parameter(Mandatory=$false,ParameterSetName='Graceful')] [switch]$Graceful,
                [Parameter(Mandatory=$false,ParameterSetName='Graceful')][double]$Delay
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
                $GracefulState = if ($Graceful) { "YES" } else { "NO" }

                $payload = @{name=$Name;graceful=$GracefulState}
                if ($PSCmdlet.ParameterSetName -eq 'Graceful') {
                    Write-Verbose "Graceful shutdown requested for service"
                    If ($Delay)
                    {
                        $payload.Add("delay", $Delay)
                    }
                }
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType service -Payload $payload -Verbose:$VerbosePreference -Action disable
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
