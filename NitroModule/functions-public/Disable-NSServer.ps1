        function Disable-NSServer {
            <#
            .SYNOPSIS
                Disable the NetScaler Server
            .DESCRIPTION
                Disable the NetScaler Server
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the server. Can be changed after the name is created. Minimum length = 1.
            .PARAMETER Delay
                Time, in seconds, after which all the services configured on the server are disabled.
            .PARAMETER Graceful
                Shut down gracefully, without accepting any new connections, and disabling each service when all of its connections are closed. Default value: NO. Possible values = YES, NO
            .EXAMPLE
                Disable-NSServer -NSSession $Session -Name $ServerName
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
                <#
                disable

                URL:http://<NSIP>/nitro/v1/config/

                HTTP Method:POST

                Request Payload:JSON

                object={
                "params":{
                      "warning":<String_value>,
                      "onerror":<String_value>,
                      "action":"disable"
                },
                "sessionid":"##sessionid",
                "server":{
                      "name":<String_value>,
                }}

                Response Payload:JSON

                { "errorcode": 0, "message": "Done", "severity": <String_value> }            
                #>
                $GracefulState = if ($Graceful) { "YES" } else { "NO" }

                $payload = @{name=$Name;graceful=$GracefulState}
                If ($Delay)
                {
                    $payload.Add("delay", $Delay)
                }
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType server -Payload $payload -Verbose:$VerbosePreference -Action disable
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
