    # SOLVED: Disable-NSService renders the NetScaler unresponsive (stupid me bound the service to localhost on HTTP 80 (same as REST Web services) DOH!)
        function Disable-NSService {
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
