<#
.SYNOPSIS
  Change the TACACS Server priority on the NetScaler.
.DESCRIPTION
  Change the TACACS Server priority on the NetScaler, using the Invoke-RestMethod cmdlet for the REST API calls.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-09-05
  Purpose:        Created to quickly change the TACACS Server priority at Generali

  Copyright (c) cognition IT. All rights reserved.
#>

# Variables
#    $NSIPArray = @("192.168.0.2","192.168.0.202")
    $NSIPArray = @("192.168.59.2")
    $ContentType = "application/json"

# Get User credentials for logon to NetScaler(s)
    $NSCreds = Get-Credential

    $NSUserName = $NSCreds.UserName
    $NSUserPW = $NSCreds.GetNetworkCredential().password.Tostring()

# DEBUG info
    Write-Host "NSUserName = $NSUserName"
    Write-Host "NSUserPW = $NSUserPW"

# Ensuring no Certificate errors get in the way of script execution
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
# Note: This setting is per session setting and will be valid only for given session or PowerShell Window.

foreach ($NSIP in $NSIPArray)
{
    #region Login on the NetScaler and create a session
    $Login = ConvertTo-Json @{"login" = @{"username"=$NSUserName;"password"=$NSUserPW;"timeout"=”900”}}
    $NSIP = $NSIP.ToString()
    try
    {
        Write-Host "Logging into the NetScaler with IP-address: " -NoNewline -ForegroundColor Green
        Write-Host "$NSIP" -ForegroundColor Yellow
        $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/login" -Body $Login -ContentType "application/json" -Method POST -SessionVariable NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue
    }
    catch [Exception]
    {
        Throw $_
    }
    #endregion

    #region Get the current Global Binding for the faulty TACACS server
    <# get
        URL:http://<netscaler-ip-address>/nitro/v1/config/systemglobal_authenticationtacacspolicy_binding
        HTTP Method:GET
        Request Headers:
            Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
            Accept:application/json
        Response:
            HTTP Status Code on Success: 200 OK
            HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
        Response Header:
            Content-Type:application/json
            Response Payload:
            { "systemglobal_authenticationtacacspolicy_binding": [ {
                  "priority":<Double_value>,
                  "builtin":<String[]_value>,
                  "policyname":<String_value>
            }]}
    #>
    $strURL = "http://$NSIP/nitro/v1/config/systemglobal_authenticationtacacspolicy_binding"

    # Method #1: Making the REST API call to the NetScaler
    $results = Invoke-RestMethod -Method Get -Uri $strURL -ContentType "application/json" -WebSession $NetScalerSession #-Verbose:$true
    Write-Host "Current TACACS bindings and priorities are: " -ForegroundColor Green
    $results.systemglobal_authenticationtacacspolicy_binding | Format-Table
    #endregion

    # Add a new binding (with higher priority value) for the TACACS server
    

    # Close the NetScaler Session
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType "application/json" -WebSession $NetScalerSession

}

<#
add:
    URL:http://<netscaler-ip-address/nitro/v1/config/systemglobal_authenticationtacacspolicy_binding
    HTTP Method:PUT
    Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
    Request Payload:
        {
        "systemglobal_authenticationtacacspolicy_binding":{
              "policyname":<String_value>,
              "priority":<Double_value>
        }}
    Response:
        HTTP Status Code on Success: 201 Created
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error

delete:
    URL:http://<netscaler-ip-address>/nitro/v1/config/systemglobal_authenticationtacacspolicy_binding
    Query-parameters:
    args
        http://<netscaler-ip-address>/nitro/v1/config/systemglobal_authenticationtacacspolicy_binding?args=policyname:<String_value>
    HTTP Method:DELETE
    Request Header:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Response:
        HTTP Status Code on Success: 200 OK
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error


#>


<#
    # Get the current Global Binding for the faulty TACACS server
    $strURL = "http://$NSIP/nitro/v1/config/systemglobal_authenticationtacacspolicy_binding"

    $JSONpayload = @{
    "systemparameter"= @{
        "doppler"="DISABLED";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $results = Invoke-RestMethod -Method Put -Uri $strURL -Body $JSONpayload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -Credential $NSCreds

#>