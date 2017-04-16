# 20170409: Working setup for demo computer
# Add the Basic NetScaler (First Logon Wizard & Modes & Features) configuration to the NetScaler CPX

#region NITRO settings
    $ContentType = "application/json"
    # Prompt for credentials
#    $MyCreds =  Get-Credential
    # Build my own credentials variable, based on password string
    $PW = ConvertTo-SecureString "nsroot" -AsPlainText -Force
    $MyCreds = New-Object System.Management.Automation.PSCredential ("nsroot", $PW)

    $NSUserName = "nsroot"
    $NSUserPW = "nsroot"

    $strDate = Get-Date -Format yyyyMMddHHmmss
<#
    # Store original VerbosePreference setting for later
    Write-Host ("Original Verbose Preference is: " + $VerbosePreference) -ForegroundColor Cyan
    $VerbosePrefOriginal = $VerbosePreference
    $VerbosePreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
    Write-Host ("Verbose Preference is changed to: " + $VerbosePreference) -ForegroundColor Cyan
#>
#endregion NITRO settings

#region Container settings
#$DockerHostIP = "192.168.0.51"
$DockerHostIP = "192.168.59.101"

$WebserverBlueIP = "172.17.0.4"
$WebServerBluePort = "32772"
$WebserverGreenIP = "172.17.0.3"
$WebServerGreenPort = "32771"

$CPXIP = "172.17.0.2"
$CPXPortNSIP = "32769"
$CPXPortVIP = "32768"

$NSIP = ($DockerHostIP + ":" + $CPXPortNSIP)

#endregion

Write-Host "---------------------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Changing LB configuration of NetScaler CPX with NITRO: | " -ForegroundColor Yellow
Write-Host "---------------------------------------------------------- " -ForegroundColor Yellow

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

# ----------------------------------------
# | Method #1: Using the SessionVariable |
# ----------------------------------------
#region Start NetScaler NITRO Session
    #Connect to the NetScaler VPX Virtual Appliance
    $Login = @{"login" = @{"username"=$NSUserName;"password"=$NSUserPW;"timeout"=”900”}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/login" -Body $Login -Method POST -SessionVariable NetScalerSession -ContentType $ContentType -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion Start NetScaler NITRO Session

#region disable LB Service blue
    <#
    disable
    URL:http://<netscaler-ip-address>/nitro/v1/config/service?action=disable
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"service":{
          "name":<String_value>,
          "delay":<Double_value>,
          "graceful":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 200 OK
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/service?action=disable"

    # 
    $payload = @{
        "service"= @{
          "name"="svc_webserver_blue"
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference

#endregion Disable LB Service blue

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

#region Get LB Services stats
    <#
    get (all)
    URL:http://<netscaler-ip-address>/nitro/v1/stat/service
    Query-parameters:
    args
    http://<netscaler-ip-address>/nitro/v1/stat/service?args=name:<String_value>,detail:<Boolean_value>,fullvalues:<Boolean_value>,ntimes:<Double_value>,logfile:<String_value>,clearstats:<String_value>
    Use this query-parameter to get service resources based on additional properties.
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
    { "service": [ {
          "name":<String_value>,
          "svrestablishedconn":<Double_value>,
          "curclntconnections":<Double_value>,
          "servicetype":<String_value>,
          "totalrequests":<Double_value>,
          "surgecount":<Double_value>,
          "responsebytesrate":<Double_value>,
          "totalresponses":<Double_value>,
          "requestbytesrate":<Double_value>,
          "throughput":<Double_value>,
          "throughputrate":<Double_value>,
          "curtflags":<Double_value>,
          "cursrvrconnections":<Double_value>,
          "primaryipaddress":<String_value>,
          "activetransactions":<Double_value>,
          "responsesrate":<Double_value>,
          "maxclients":<Double_value>,
          "avgsvrttfb":<Double_value>,
          "curload":<Double_value>,
          "totalrequestbytes":<Double_value>,
          "curreusepool":<Double_value>,
          "state":<String_value>,
          "vsvrservicehits":<Double_value>,
          "totalresponsebytes":<Double_value>,
          "primaryport":<Integer_value>,
          "requestsrate":<Double_value>,
          "vsvrservicehitsrate":<Double_value>
    }]}
    #>
    # Specifying the correct URL 
#    $strURI = "http://$NSIP/nitro/v1/stat/service?args=name:svc_webserver_green"
    $strURI = "http://$NSIP/nitro/v1/stat/service"

    # Method #1: Making the REST API call to the NetScaler
#    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    Write-Host "response: " -ForegroundColor Green
    $response.service | Select-Object name, primaryipaddress, primaryport, servicetype, state, totalrequests, cursrvrconnections, svrestablishedconn
#endregion Get LB Services stats

#region Get LB vServer stats
    <#
    get (all)
    URL:http://<netscaler-ip-address>/nitro/v1/stat/lbvserver
    Query-parameters:
    args
    http://<netscaler-ip-address>/nitro/v1/stat/lbvserver?args=name:<String_value>,detail:<Boolean_value>,fullvalues:<Boolean_value>,ntimes:<Double_value>,logfile:<String_value>,clearstats:<String_value>,sortby:<String_value>,sortorder:<String_value>,sortorder:<String_value>
    Use this query-parameter to get lbvserver resources based on additional properties.
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
    { "lbvserver": [ {
          "name":<String_value>,
          "curclntconnections":<Double_value>,
          "establishedconn":<Double_value>,
          "totalpktssent":<Double_value>,
          "labelledconn":<Double_value>,
          "tothits":<Double_value>,
          "totalrequests":<Double_value>,
          "sothreshold":<Double_value>,
          "cursubflowconn":<Double_value>,
          "surgecount":<Double_value>,
          "responsebytesrate":<Double_value>,
          "invalidrequestresponsedropped":<Double_value>,
          "totalresponses":<Double_value>,
          "requestbytesrate":<Double_value>,
          "type":<String_value>,
          "hitsrate":<Double_value>,
          "cursrvrconnections":<Double_value>,
          "pktsrecvdrate":<Double_value>,
          "primaryipaddress":<String_value>,
          "vsvrsurgecount":<Double_value>,
          "pushlabel":<Double_value>,
          "responsesrate":<Double_value>,
          "deferredreq":<Double_value>,
          "curmptcpsessions":<Double_value>,
          "totspillovers":<Double_value>,
          "svcsurgecount":<Double_value>,
          "totalrequestbytes":<Double_value>,
          "invalidrequestresponse":<Double_value>,
          "state":<String_value>,
          "vslbhealth":<Double_value>,
          "deferredreqrate":<Double_value>,
          "actsvcs":<Double_value>,
          "totalpktsrecvd":<Double_value>,
          "pktssentrate":<Double_value>,
          "totalresponsebytes":<Double_value>,
          "primaryport":<Integer_value>,
          "requestsrate":<Double_value>,
          "totvserverdownbackuphits":<Double_value>,
          "inactsvcs":<Double_value>
    }]}
    #>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/stat/lbvserver?args=name:vsvr_webserver_81"

    # Method #1: Making the REST API call to the NetScaler
#    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    Write-Host "response: " -ForegroundColor Green
    $response.lbvserver | Select-object name, primaryipaddress, primaryport, type, state, vslbhealth, actsvcs, tothits
#endregion Add LB Services


#region End NetScaler NITRO Session
    #Disconnect from the NetScaler VPX Virtual Appliance
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session

