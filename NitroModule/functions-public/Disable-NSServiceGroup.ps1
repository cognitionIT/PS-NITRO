        function Disable-NSServiceGroup {
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
