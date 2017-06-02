    function Enable-NSCEIP {
        <#
        .SYNOPSIS
            Enable the Citrix Customer Experience Improvement Program
        .DESCRIPTION
            Enable the Citrix Customer Experience Improvement Program
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Enable-NSCEIP -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            <#
            update

            URL:http://<NSIP>/nitro/v1/config/
            HTTP Method:PUT
            Request Payload:JSON
            {
            "params": {
                  "warning":<String_value>,
                  "onerror":<String_value>"
            },
            sessionid":"##sessionid",
            "systemparameter":{
                  "rbaonresponse":<String_value>,
                  "promptstring":<String_value>,
                  "natpcbforceflushlimit":<Double_value>,
                  "natpcbrstontimeout":<String_value>,
                  "timeout":<Double_value>,
                  "localauth":<String_value>,
                  "minpasswordlen":<Double_value>,
                  "strongpassword":<String_value>,
                  "restrictedtimeout":<String_value>,
                  "fipsusermode":<String_value>,
                  "doppler":<String_value>,
                  "googleanalytics":<String_value>,
            }}

            Response Payload:JSON

            { "errorcode": 0, "message": "Done", "severity": <String_value> }

            doppler<String>     Enable or disable Doppler. Default value: DISABLED Possible values = ENABLED, DISABLED
            #>
            $payload = @{}
        }
        Process {
            $payload.Add("doppler","ENABLED")        
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType systemparameter -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
