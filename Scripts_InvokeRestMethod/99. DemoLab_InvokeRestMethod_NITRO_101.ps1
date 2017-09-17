# Constants used in the script
    $ContentType = "application/json"
# Variables used in the script
    $NSIP = "192.168.59.2"
    $NSUserName = "nsroot"
    $NSUserPW = "nsroot"

#region Action #1: Connect to the NetScaler VPX and start a Session (using a Variable)
<# Getting Started Guide: Connecting to the NetScaler Appliance
The first step towards using NITRO is to establish a session with the NetScaler appliance and then you must specify the username and password in the login object. 
    Request:
    HTTP Method         POST
    URL                 http://10.102.29.60/nitro/v1/config/login
    Request Payload
                        {
                        "login":
                        {
                        "username":"<username>",
                        "password":"<password>"
                        }
                        }
    Response:
    HTTP Status Code on Success: 200 OK
    HTTP Status Code on Failure: 4xx <string> or 5xx <string> 
    Response Header
    Set-Cookie:             NITRO_AUTH_TOKEN=<tokenvalue>; path=/nitro/v1
#>

# 1a. Create the JSON payload (using ConvertTo-JSON cmdlet)
    $JSONPayload = ConvertTo-JSON @{"login" = @{"username"=$NSUserName;"password"=$NSUserPW;}} -Depth 100

# Check the JSON payload formatting
    Write-Host "JSON payload:" -ForegroundColor Yellow
    Write-Host $JSONPayload -ForegroundColor Green

# 1b. Make the REST API call
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/login" -Body $JSONPayload -Method POST -SessionVariable NetScalerSession -ContentType $ContentType -Verbose:$true

# Show the results of the REST API call
    Write-Host "Results:" -ForegroundColor Yellow
    Write-Host $dummy -ForegroundColor Green

# Show the Session Variable
    Write-Host "Session Variable:" -ForegroundColor Yellow
    Write-Host $NetScalerSession -ForegroundColor Green

#endregion

#region Get NetScaler Basic & Advanced Features
<#
    get (all)
    URL:          http://<netscaler-ip-address>/nitro/v1/config/nsfeature
    HTTP Method:  GET
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/nsfeature"

    # Method #1: Making the REST API call to the NetScaler
    $Response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true

    # Showing Response output
    Write-Host "NetScaler Features: " -ForegroundColor Yellow
    Write-Host $Response.nsfeature -ForegroundColor Green

#endregion Get NetScaler Basic & Advanced Features

#region Enable NetScaler Basic & Advanced Features
<#
    enable
    URL:http://<netscaler-ip-address>/nitro/v1/config/nsfeature?action=enable
    HTTP Method:POST
    Request Payload:
        {"nsfeature":{
              "feature":<String[]_value>
        }}
    Response:
        HTTP Status Code on Success: 200 OK
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/nsfeature?action=enable"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # enable ns feature WL SP LB SSL SSLVPN REWRITE RESPONDER

    $JSONPayload = ConvertTo-Json @{
    "nsfeature"= @{
        "feature"=@("LB","SSL","SSLVPN","REWRITE","RESPONDER")
        }
    } -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $JSONPayload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $dummy = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true
#endregion Enable NetScaler Basic & Advanced Features








#region Action #99: Close the NetScaler Session

<# Getting Started Guide: Disconnecting from the NetScaler Appliance
    To logout of the NetScaler appliance:
    Request:
    HTTP Method      POST
    URL              http://<netscaler-ip-address>/nitro/v1/config/logout
    Request Payload
                    {
                    "logout":{}
                    }
    Response:
    HTTP Status Code on Success: 200 OK
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors).
#>

# 99a. Create the JSON payload (using ConvertTo-JSON cmdlet)
    $JSONPayload = ConvertTo-JSON @{"logout" = @{}} -Depth 100

# Check the JSON payload formatting
    Write-Host "JSON payload:" -ForegroundColor Yellow
    Write-Host $JSONPayload -ForegroundColor Green

# 1b. Make the REST API call
    $dummy = Invoke-RestMethod -Method POST -Uri "http://$NSIP/nitro/v1/config/logout" -Body $JSONPayload -WebSession $NetScalerSession -ContentType $ContentType -Verbose:$true

# Show the results of the REST API call
    Write-Host "Results:" -ForegroundColor Yellow
    Write-Host $dummy -ForegroundColor Green

# Show the Session Variable
    Write-Host "Session Variable:" -ForegroundColor Yellow
    Write-Host $NetScalerSession -ForegroundColor Green
#endregion
