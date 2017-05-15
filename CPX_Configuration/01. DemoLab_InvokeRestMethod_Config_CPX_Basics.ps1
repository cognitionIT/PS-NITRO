<#
.SYNOPSIS
  Configure a Basic Load Balancing configuration on the NetScaler CPX.
.DESCRIPTION
  Configure a Basic Load Balancing configuration on the NetScaler CPX, using the Invoke-RestMethod cmdlet for the REST API calls.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-05-04
  Purpose:        Created as part of the demo scripts for the PowerShell Conference EU 2017 in Hannover

  Copyright (c) cognition IT. All rights reserved.
#>

#region NITRO settings
    $ContentType = "application/json"
    $PW = ConvertTo-SecureString "nsroot" -AsPlainText -Force
    $MyCreds = New-Object System.Management.Automation.PSCredential ("nsroot", $PW)

    $NSUserName = "nsroot"
    $NSUserPW = "nsroot"

    $strDate = Get-Date -Format yyyyMMddHHmmss
#endregion NITRO settings

#region Container settings
    $DockerHostIP = "192.168.0.51"

    $WebserverBlueIP = "172.17.0.4"
    $WebServerBluePort = "32772"
    $WebserverGreenIP = "172.17.0.3"
    $WebServerGreenPort = "32771"

    $CPXIP = "172.17.0.2"
    $CPXPortNSIP = "32769"
    $CPXPortVIP = "32768"

    $NSIP = ($DockerHostIP + ":" + $CPXPortNSIP)
#endregion

Write-Host "-------------------------------- " -ForegroundColor Yellow
Write-Host "| Check the Docker Containers: | " -ForegroundColor Yellow
Write-Host "-------------------------------- " -ForegroundColor Yellow

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

#region Open webbrowsers to test the container websites
    Write-Host "Checking the Blue webserver ..." -ForegroundColor Green
    Start-sleep -Seconds 5
    Invoke-Expression "cmd.exe /C start http://$DockerHostIP`:$WebServerBluePort/index.html"

    Write-Host "Checking the Green webserver ..." -ForegroundColor Green
    Start-sleep -Seconds 5
    Invoke-Expression "cmd.exe /C start http://$DockerHostIP`:$WebServerGreenPort/index.html"

    Write-Host "Checking the CPX NSIP ..." -ForegroundColor Green
    Start-sleep -Seconds 5
    Invoke-Expression "cmd.exe /C start http://$DockerHostIP`:$CPXPortNSIP"

    Write-Host "Checking the CPX VIP ..." -ForegroundColor Green
    Start-sleep -Seconds 5
    Invoke-Expression "cmd.exe /C start http://$DockerHostIP`:$CPXPortVIP"
#endregion Open webbrowsers

Write-Host "------------------------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Pushing the LB configuration to NetScaler CPX with NITRO: | " -ForegroundColor Yellow
Write-Host "------------------------------------------------------------- " -ForegroundColor Yellow

Start-Sleep -Seconds 5

# ----------------------------------------
# | Method #1: Using the SessionVariable |
# ----------------------------------------
#region Start NetScaler NITRO Session
    #Connect to the NetScaler CPX
    $Login = @{"login" = @{"username"=$NSUserName;"password"=$NSUserPW;"timeout"=”900”}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/login" -Body $Login -Method POST -SessionVariable NetScalerSession -ContentType $ContentType -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion Start NetScaler NITRO Session

#region Add LB Services (bulk)
    <#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/service
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"service":{
          "name":<String_value>,
          "ip":<String_value>,
          "servername":<String_value>,
          "servicetype":<String_value>,
          "port":<Integer_value>,
          "cleartextport":<Integer_value>,
          "cachetype":<String_value>,
          "maxclient":<Double_value>,
          "healthmonitor":<String_value>,
          "maxreq":<Double_value>,
          "cacheable":<String_value>,
          "cip":<String_value>,
          "cipheader":<String_value>,
          "usip":<String_value>,
          "pathmonitor":<String_value>,
          "pathmonitorindv":<String_value>,
          "useproxyport":<String_value>,
          "sc":<String_value>,
          "sp":<String_value>,
          "rtspsessionidremap":<String_value>,
          "clttimeout":<Double_value>,
          "svrtimeout":<Double_value>,
          "customserverid":<String_value>,
          "serverid":<Double_value>,
          "cka":<String_value>,
          "tcpb":<String_value>,
          "cmp":<String_value>,
          "maxbandwidth":<Double_value>,
          "accessdown":<String_value>,
          "monthreshold":<Double_value>,
          "state":<String_value>,
          "downstateflush":<String_value>,
          "tcpprofilename":<String_value>,
          "httpprofilename":<String_value>,
          "hashid":<Double_value>,
          "comment":<String_value>,
          "appflowlog":<String_value>,
          "netprofile":<String_value>,
          "td":<Double_value>,
          "processlocal":<String_value>,
          "dnsprofilename":<String_value>,
          "monconnectionclose":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/service"

    # add service svc_webserver_green HTTP 172.17.0.3 8080
    # add service svc_webserver_blue HTTP 172.17.0.4 8080
    $payload = @{
        "service"= @(
            @{"name"="svc_webserver_green";"ip"="$WebserverGreenIP";"servicetype"="HTTP";"port"=8080},
            @{"name"="svc_webserver_blue";"ip"="$WebserverBlueIP";"servicetype"="HTTP";"port"=8080}
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add LB Services

#region Add LB vServers
<#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/lbvserver
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"lbvserver":{
          "name":<String_value>,
          "servicetype":<String_value>,
          "ipv46":<String_value>,
          "ippattern":<String_value>,
          "ipmask":<String_value>,
          "port":<Integer_value>,
          "range":<Double_value>,
          "persistencetype":<String_value>,
          "timeout":<Double_value>,
          "persistencebackup":<String_value>,
          "backuppersistencetimeout":<Double_value>,
          "lbmethod":<String_value>,
          "hashlength":<Double_value>,
          "netmask":<String_value>,
          "v6netmasklen":<Double_value>,
          "backuplbmethod":<String_value>,
          "cookiename":<String_value>,
          "rule":<String_value>,
          "listenpolicy":<String_value>,
          "listenpriority":<Double_value>,
          "resrule":<String_value>,
          "persistmask":<String_value>,
          "v6persistmasklen":<Double_value>,
          "pq":<String_value>,
          "sc":<String_value>,
          "rtspnat":<String_value>,
          "m":<String_value>,
          "tosid":<Double_value>,
          "datalength":<Double_value>,
          "dataoffset":<Double_value>,
          "sessionless":<String_value>,
          "state":<String_value>,
          "connfailover":<String_value>,
          "redirurl":<String_value>,
          "cacheable":<String_value>,
          "clttimeout":<Double_value>,
          "somethod":<String_value>,
          "sopersistence":<String_value>,
          "sopersistencetimeout":<Double_value>,
          "healththreshold":<Double_value>,
          "sothreshold":<Double_value>,
          "sobackupaction":<String_value>,
          "redirectportrewrite":<String_value>,
          "downstateflush":<String_value>,
          "backupvserver":<String_value>,
          "disableprimaryondown":<String_value>,
          "insertvserveripport":<String_value>,
          "vipheader":<String_value>,
          "authenticationhost":<String_value>,
          "authentication":<String_value>,
          "authn401":<String_value>,
          "authnvsname":<String_value>,
          "push":<String_value>,
          "pushvserver":<String_value>,
          "pushlabel":<String_value>,
          "pushmulticlients":<String_value>,
          "tcpprofilename":<String_value>,
          "httpprofilename":<String_value>,
          "dbprofilename":<String_value>,
          "comment":<String_value>,
          "l2conn":<String_value>,
          "oracleserverversion":<String_value>,
          "mssqlserverversion":<String_value>,
          "mysqlprotocolversion":<Double_value>,
          "mysqlserverversion":<String_value>,
          "mysqlcharacterset":<Double_value>,
          "mysqlservercapabilities":<Double_value>,
          "appflowlog":<String_value>,
          "netprofile":<String_value>,
          "icmpvsrresponse":<String_value>,
          "rhistate":<String_value>,
          "newservicerequest":<Double_value>,
          "newservicerequestunit":<String_value>,
          "newservicerequestincrementinterval":<Double_value>,
          "minautoscalemembers":<Double_value>,
          "maxautoscalemembers":<Double_value>,
          "persistavpno":<Double[]_value>,
          "skippersistency":<String_value>,
          "td":<Double_value>,
          "authnprofile":<String_value>,
          "macmoderetainvlan":<String_value>,
          "dbslb":<String_value>,
          "dns64":<String_value>,
          "bypassaaaa":<String_value>,
          "recursionavailable":<String_value>,
          "processlocal":<String_value>,
          "dnsprofilename":<String_value>,
          "lbprofilename":<String_value>,
          "redirectfromport":<Integer_value>,
          "httpsredirecturl":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/lbvserver"

    # add lb vserver cpx-vip HTTP 172.17.0.2 81
    $payload = @{
    "lbvserver"= @{
        "name"="vsvr_webserver_81";
        "servicetype"="HTTP";
        "ipv46"="$CPXIP";
        "port"=81;
        "lbmethod"="ROUNDROBIN"
       }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add LB vServers

#region Bind Service to vServer (bulk)
<#
    add:
    URL:http://<netscaler-ip-address/nitro/v1/config/lbvserver_service_binding
    HTTP Method:PUT
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {
    "lbvserver_service_binding":{
          "name":<String_value>,
          "servicename":<String_value>,
          "weight":<Double_value>,
          "servicegroupname":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/lbvserver_service_binding"

    # bind lb vserver cpx-vip db1
    $payload = @{
    "lbvserver_service_binding"= @(
            @{"name"="vsvr_webserver_81";"servicename"="svc_webserver_green";"weight"=1},
            @{"name"="vsvr_webserver_81";"servicename"="svc_webserver_blue";"weight"=1}
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind Service to vServer

#region End NetScaler NITRO Session
    #Disconnect from the NetScaler CPX
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session

