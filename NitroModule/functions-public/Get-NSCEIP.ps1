    function Get-NSCEIP {
        <#
        .SYNOPSIS
            Retrieve the Citrix Customer Experience Improvement Program status
        .DESCRIPTION
            Retrieve the Citrix Customer Experience Improvement Program status
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Get-NSCEIP -NSSession $Session
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
            get (all)

            URL:http://<NSIP>/nitro/v1/config/systemparameter
            Query-parameters:
            HTTP Method:GET
            Response Payload:JSON
            { "errorcode": 0, "message": "Done", "severity": <String_value>, "systemparameter": [ {
                  "rbaonresponse":<String_value>,
                  "promptstring":<String_value>,
                  "natpcbforceflushlimit":<Double_value>,
                  "natpcbrstontimeout":<String_value>,
                  "timeout":<Double_value>,
                  "maxclient":<Double_value>,
                  "localauth":<String_value>,
                  "minpasswordlen":<Double_value>,
                  "strongpassword":<String_value>,
                  "restrictedtimeout":<String_value>,
                  "fipsusermode":<String_value>,
                  "doppler":<String_value>,
                  "googleanalytics":<String_value>
            }]}
            #>
            $payload = @{}
        }
        Process {
            $payload.Add("doppler","ENABLED")        
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemparameter -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['systemparameter'])
            {
                return $response.systemparameter.doppler
            }
            else
            {
                return $null
            }
        }
    }
