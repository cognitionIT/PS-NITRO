<#
.SYNOPSIS
  Configure Basic Load Balancing Settings on the NetScaler VPX.
.DESCRIPTION
  Configure Basic Load Balancing Settings (SF LB example) on the NetScaler VPX, using the Invoke-RestMethod cmdlet for the REST API calls.
.NOTES
  Version:        1.1
  Creation Date:  2017-05-04
  Purpose:        Created as part of the demo scripts for the PowerShell Conference EU 2017 in Hannover
  Author:         Esther Barthel, MSc
  Last Updated:   2017-08-07
  Purpose:        Adding responder best practice for HTTP to HTTPS redirection, based on https://support.citrix.com/article/CTX120664

  Copyright (c) cognition IT. All rights reserved.
#>

#region NITRO settings
    $ContentType = "application/json"
    $SubNetIP = "192.168.0"
    $NSIP = $SubNetIP + ".2"
    # Build my own credentials variable, based on password string
    $PW = ConvertTo-SecureString "nsroot" -AsPlainText -Force
    $MyCreds = New-Object System.Management.Automation.PSCredential ("nsroot", $PW)
    $FileRoot = "C:\GitHub\PS-NITRO\Scripts_InvokeRestMethod"

    $NSUserName = "nsroot"
    $NSUserPW = "nsroot"

    $strDate = Get-Date -Format yyyyMMddHHmmss
#endregion NITRO settings

Write-Host "---------------------------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Pushing the LB configuration to NetScaler with NITRO:        | " -ForegroundColor Yellow
Write-Host "---------------------------------------------------------------- " -ForegroundColor Yellow

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

# ----------------------------------------
# | Method #1: Using the SessionVariable |
# ----------------------------------------
#region Start NetScaler NITRO Session
    #Connect to the NetScaler VPX
    $Login = @{"login" = @{"username"=$NSUserName;"password"=$NSUserPW;"timeout"=”900”}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/login" -Body $Login -Method POST -SessionVariable NetScalerSession -ContentType $ContentType -Verbose:$VerbosePreference
#endregion Start NetScaler NITRO Session

# --------------------------------------
# | Enable required NetScaler Features |
# --------------------------------------
#region Enable NetScaler Basic & Advanced Features
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/nsfeature?action=enable"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # enable ns feature SSL

    $payload = @{
    "nsfeature"= @{
        "feature"=@("LB","REWRITE","RESPONDER")
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Enable NetScaler Basic & Advanced Features

# --------------------------------------
# | Add App Expert settings            |
# --------------------------------------
#region Add Rewrite Actions
<#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/rewriteaction
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"rewriteaction":{
          "name":<String_value>,
          "type":<String_value>,
          "target":<String_value>,
          "stringbuilderexpr":<String_value>,
          "pattern":<String_value>,
          "search":<String_value>,
          "bypasssafetycheck":<String_value>,
          "refinesearch":<String_value>,
          "comment":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/rewriteaction"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # 

    $payload = @{
    "rewriteaction"= @{
           "name"="rwa_store_redirect";
           "type"="replace";
           "target"="HTTP.REQ.URL";
           "stringbuilderexpr"="""/Citrix/StoreWeb""";
           "comment"="created by PowerShell script";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add Rewrite Actions

#region Add Rewrite Policies
<#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/rewritepolicy
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"rewritepolicy":{
          "name":<String_value>,
          "rule":<String_value>,
          "action":<String_value>,
          "undefaction":<String_value>,
          "comment":<String_value>,
          "logaction":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/rewritepolicy"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # 

    $payload = @{
    "rewritepolicy"= @{
           "name"="rwp_store_redirect";
           "rule"="HTTP.REQ.URL.EQ(""/"")";
           "action"="rwa_store_redirect";
           "comment"="created by PowerShell script";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add Rewrite Policies

#region Add Responder Actions
<#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/responderaction
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"responderaction":{
          "name":<String_value>,
          "type":<String_value>,
          "target":<String_value>,
          "htmlpage":<String_value>,
          "bypasssafetycheck":<String_value>,
          "comment":<String_value>,
          "responsestatuscode":<Double_value>,
          "reasonphrase":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/responderaction"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # 

    $payload = @{
    "responderaction"= @{
          "name"="rspa_http_https_redirect";
          "type"="redirect";
          "target"="""https://"" + HTTP.REQ.HOSTNAME.HTTP_URL_SAFE + HTTP.REQ.URL.PATH_AND_QUERY.HTTP_URL_SAFE";
          "comment"="created by PowerShell script";
          "responsestatuscode"=302;
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add Responder Actions

#region Add Responder Policies
<#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/responderpolicy
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"responderpolicy":{
          "name":<String_value>,
          "rule":<String_value>,
          "action":<String_value>,
          "undefaction":<String_value>,
          "comment":<String_value>,
          "logaction":<String_value>,
          "appflowaction":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/responderpolicy"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # 

    $payload = @{
    "responderpolicy"= @{
           "name"="rspp_http_https_redirect";
           "rule"="HTTP.REQ.IS_VALID";
           "action"="rspa_http_https_redirect";
           "comment"="created by PowerShell script";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add Responder Policies


# ----------------------------------------
# | Traffic Management configuration     |
# ----------------------------------------
#region Add LB Servers (bulk)
<#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/server
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"server":{
          "name":<String_value>,
          "ipaddress":<String_value>,
          "domain":<String_value>,
          "translationip":<String_value>,
          "translationmask":<String_value>,
          "domainresolveretry":<Integer_value>,
          "state":<String_value>,
          "ipv6address":<String_value>,
          "comment":<String_value>,
          "td":<Double_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/server"

    # Creating the right payload formatting (mind the Depth for the nested arrays)

    $payload = @{
        "server"= @(
#            @{"name"="localhost"; "ipaddress"="127.0.0.1"},
            @{"name"="lb_svr_alwaysUP"; "ipaddress"="1.1.1.1"},
            @{"name"="SF1"; "ipaddress"=($SubNetIP + ".21")},
            @{"name"="SF2"; "ipaddress"=($SubNetIP + ".22")}
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add LB Servers

#region Add LB Services
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

    # add 
    $payload = @{
        "service"= @{
          "name"="svc_alwaysUP";
#          "servername"="localhost";
          "servername"="lb_svr_alwaysUP";
          "servicetype"="HTTP";
          "port"=80;
          "comment"="created by PowerShell script";
        }
    } | ConvertTo-Json -Depth 5

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add LB Services

#region Add ServiceGroups
<#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/servicegroup
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"servicegroup":{
          "servicegroupname":<String_value>,
          "servicetype":<String_value>,
          "cachetype":<String_value>,
          "td":<Double_value>,
          "maxclient":<Double_value>,
          "maxreq":<Double_value>,
          "cacheable":<String_value>,
          "cip":<String_value>,
          "cipheader":<String_value>,
          "usip":<String_value>,
          "pathmonitor":<String_value>,
          "pathmonitorindv":<String_value>,
          "useproxyport":<String_value>,
          "healthmonitor":<String_value>,
          "sc":<String_value>,
          "sp":<String_value>,
          "rtspsessionidremap":<String_value>,
          "clttimeout":<Double_value>,
          "svrtimeout":<Double_value>,
          "cka":<String_value>,
          "tcpb":<String_value>,
          "cmp":<String_value>,
          "maxbandwidth":<Double_value>,
          "monthreshold":<Double_value>,
          "state":<String_value>,
          "downstateflush":<String_value>,
          "tcpprofilename":<String_value>,
          "httpprofilename":<String_value>,
          "comment":<String_value>,
          "appflowlog":<String_value>,
          "netprofile":<String_value>,
          "autoscale":<String_value>,
          "memberport":<Integer_value>,
          "monconnectionclose":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>    
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/servicegroup"

    # 
    $payload = @{
    "servicegroup"= @{
          "servicegroupname"="svcgrp_SFStore";
          "servicetype"="HTTP";
          "cacheable"="YES";
          "healthmonitor"="YES";
          "state"="ENABLED"
          "appflowlog"="ENABLED";
          "autoscale"="DISABLED";
          "comment"="created by PowerShell script";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add ServiceGroups

#region Add Servers to ServiceGroup (bulk)
<#
    add:
    URL:http://<netscaler-ip-address/nitro/v1/config/servicegroup_servicegroupmember_binding
    HTTP Method:PUT
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {
    "servicegroup_servicegroupmember_binding":{
          "servicegroupname":<String_value>,
          "ip":<String_value>,
          "servername":<String_value>,
          "port":<Integer_value>,
          "weight":<Double_value>,
          "customserverid":<String_value>,
          "serverid":<Double_value>,
          "state":<String_value>,
          "hashid":<Double_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/servicegroup_servicegroupmember_binding"

    # 
    $payload = @{
    "servicegroup_servicegroupmember_binding"= @(
            @{"servicegroupname"="svcgrp_SFStore";"servername"="SF1";"port"=80;"state"="ENABLED";"weight"=1},
            @{"servicegroupname"="svcgrp_SFStore";"servername"="SF2";"port"=80;"state"="ENABLED";"weight"=2}
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add Servers to ServiceGroup

#region Add Monitors (bulk)
<#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/lbmonitor
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"lbmonitor":{
          "monitorname":<String_value>,
          "type":<String_value>,
          "action":<String_value>,
          "respcode":<String[]_value>,
          "httprequest":<String_value>,
          "rtsprequest":<String_value>,
          "customheaders":<String_value>,
          "maxforwards":<Double_value>,
          "sipmethod":<String_value>,
          "sipuri":<String_value>,
          "sipreguri":<String_value>,
          "send":<String_value>,
          "recv":<String_value>,
          "query":<String_value>,
          "querytype":<String_value>,
          "scriptname":<String_value>,
          "scriptargs":<String_value>,
          "dispatcherip":<String_value>,
          "dispatcherport":<Integer_value>,
          "username":<String_value>,
          "password":<String_value>,
          "secondarypassword":<String_value>,
          "logonpointname":<String_value>,
          "lasversion":<String_value>,
          "radkey":<String_value>,
          "radnasid":<String_value>,
          "radnasip":<String_value>,
          "radaccounttype":<Double_value>,
          "radframedip":<String_value>,
          "radapn":<String_value>,
          "radmsisdn":<String_value>,
          "radaccountsession":<String_value>,
          "lrtm":<String_value>,
          "deviation":<Double_value>,
          "units1":<String_value>,
          "interval":<Integer_value>,
          "units3":<String_value>,
          "resptimeout":<Integer_value>,
          "units4":<String_value>,
          "resptimeoutthresh":<Double_value>,
          "retries":<Integer_value>,
          "failureretries":<Integer_value>,
          "alertretries":<Integer_value>,
          "successretries":<Integer_value>,
          "downtime":<Integer_value>,
          "units2":<String_value>,
          "destip":<String_value>,
          "destport":<Integer_value>,
          "state":<String_value>,
          "reverse":<String_value>,
          "transparent":<String_value>,
          "iptunnel":<String_value>,
          "tos":<String_value>,
          "tosid":<Double_value>,
          "secure":<String_value>,
          "validatecred":<String_value>,
          "domain":<String_value>,
          "ipaddress":<String[]_value>,
          "group":<String_value>,
          "filename":<String_value>,
          "basedn":<String_value>,
          "binddn":<String_value>,
          "filter":<String_value>,
          "attribute":<String_value>,
          "database":<String_value>,
          "oraclesid":<String_value>,
          "sqlquery":<String_value>,
          "evalrule":<String_value>,
          "mssqlprotocolversion":<String_value>,
          "Snmpoid":<String_value>,
          "snmpcommunity":<String_value>,
          "snmpthreshold":<String_value>,
          "snmpversion":<String_value>,
          "metrictable":<String_value>,
          "application":<String_value>,
          "sitepath":<String_value>,
          "storename":<String_value>,
          "storefrontacctservice":<String_value>,
          "hostname":<String_value>,
          "netprofile":<String_value>,
          "originhost":<String_value>,
          "originrealm":<String_value>,
          "hostipaddress":<String_value>,
          "vendorid":<Double_value>,
          "productname":<String_value>,
          "firmwarerevision":<Double_value>,
          "authapplicationid":<Double[]_value>,
          "acctapplicationid":<Double[]_value>,
          "inbandsecurityid":<String_value>,
          "supportedvendorids":<Double[]_value>,
          "vendorspecificvendorid":<Double_value>,
          "vendorspecificauthapplicationids":<Double[]_value>,
          "vendorspecificacctapplicationids":<Double[]_value>,
          "kcdaccount":<String_value>,
          "storedb":<String_value>,
          "storefrontcheckbackendservices":<String_value>,
          "trofscode":<Double_value>,
          "trofsstring":<String_value>,
          "sslprofile":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/lbmonitor"

    # add lb monitor lb_mon_SFStore STOREFRONT -scriptName nssf.pl -dispatcherIP 127.0.0.1 -dispatcherPort 3013 -LRTM ENABLED -storename Store
    # add lb monitor lb_mon_localhost PING -LRTM DISABLED -destIP 127.0.0.1
    $payload = @{
    "lbmonitor"= @( 
            @{"monitorname"="lb_mon_SFStore";"type"="STOREFRONT";"scriptname"="nssf.pl";"lrtm"="ENABLED";"storename"="Store"},
            @{"monitorname"="lb_mon_localhost";"type"="PING";"lrtm"="DISABLED";"destIP"="127.0.0.1"}
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add Monitors

#region Bind Monitor to Service
<#
    add:
    URL:http://<netscaler-ip-address/nitro/v1/config/lbmonitor_service_binding
    HTTP Method:PUT
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {
    "lbmonitor_service_binding":{
          "monitorname":<String_value>,
          "servicename":<String_value>,
          "dup_state":<String_value>,
          "dup_weight":<Double_value>,
          "servicegroupname":<String_value>,
          "state":<String_value>,
          "weight":<Double_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/lbmonitor_service_binding"

    # 
    $payload = @{
    "lbmonitor_service_binding"= @{
#          "monitorname"="ping";
          "monitorname"="lb_mon_localhost";
#          "servicename"="svc_local_http";
          "servicename"="svc_alwaysUP";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    # !! Note:ping is binded by default to a service!!
    $response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind Monitor to Service

#region Bind Monitor to ServiceGroup
<#
    add:
    URL:http://<netscaler-ip-address/nitro/v1/config/lbmonitor_servicegroup_binding
    HTTP Method:PUT
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {
    "lbmonitor_servicegroup_binding":{
          "monitorname":<String_value>,
          "servicename":<String_value>,
          "dup_state":<String_value>,
          "dup_weight":<Double_value>,
          "servicegroupname":<String_value>,
          "state":<String_value>,
          "weight":<Double_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/lbmonitor_servicegroup_binding"

    # 
    $payload = @{
    "lbmonitor_servicegroup_binding"= @{
          "monitorname"="lb_mon_SFStore";
          "servicegroupname"="svcgrp_SFStore";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind Monitor to ServiceGroup

#region Add LB vServers (bulk)
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

    # 
    $payload = @{
    "lbvserver"= @(
            @{"name"="vsvr_SFStore_http_redirect";"servicetype"="HTTP";"ipv46"=($SubNetIP + ".11");"port"=80;"lbmethod"="ROUNDROBIN"},
            @{"name"="vsvr_SFStore";"servicetype"="SSL";"ipv46"=($SubNetIP + ".11");"port"=443;"lbmethod"="ROUNDROBIN"}
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add LB vServers

#region Bind Service to vServer
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

    # 
    $payload = @{
    "lbvserver_service_binding"= @{
          "name"="vsvr_SFStore_http_redirect";
#          "servicename"="svc_local_http";
          "servicename"="svc_alwaysUP";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind Service to vServer

#region Bind ServiceGroup to vServer
<#
    add:
    URL:http://<netscaler-ip-address/nitro/v1/config/lbvserver_servicegroup_binding
    HTTP Method:PUT
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {
    "lbvserver_servicegroup_binding":{
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
    $strURI = "http://$NSIP/nitro/v1/config/lbvserver_servicegroup_binding"

    # 
    $payload = @{
    "lbvserver_servicegroup_binding"= @{
          "name"="vsvr_SFStore";
          "servicegroupname"="svcgrp_SFStore";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind ServiceGroup to vServer

#region Bind Responder Policy to vServer
<#
    add:
    URL:http://<netscaler-ip-address/nitro/v1/config/lbvserver_responderpolicy_binding
    HTTP Method:PUT
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {
    "lbvserver_responderpolicy_binding":{
          "name":<String_value>,
          "policyname":<String_value>,
          "priority":<Double_value>,
          "gotopriorityexpression":<String_value>,
          "bindpoint":<String_value>,
          "invoke":<Boolean_value>,
          "labeltype":<String_value>,
          "labelname":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/lbvserver_responderpolicy_binding"

    # 
    $payload = @{
    "lbvserver_responderpolicy_binding"= @{
          "name"="vsvr_SFStore_http_redirect";
          "policyname"="rspp_http_https_redirect";
          "priority"=100;
          "gotopriorityexpression"="END";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind Responder Policy to vServer

#region Bind Rewrite Policy to vServer
<#
    add:
    URL:http://<netscaler-ip-address/nitro/v1/config/lbvserver_rewritepolicy_binding
    HTTP Method:PUT
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {
    "lbvserver_rewritepolicy_binding":{
          "name":<String_value>,
          "policyname":<String_value>,
          "priority":<Double_value>,
          "gotopriorityexpression":<String_value>,
          "bindpoint":<String_value>,
          "invoke":<Boolean_value>,
          "labeltype":<String_value>,
          "labelname":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/lbvserver_rewritepolicy_binding"

    # 
    $payload = @{
    "lbvserver_rewritepolicy_binding"= @{
          "name"="vsvr_SFStore";
          "policyname"="rwp_store_redirect";
          "priority"=100;
          "gotopriorityexpression"="END";
          "bindpoint"="REQUEST";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind Rewrite Policy to vServer


#region End NetScaler NITRO Session
    #Disconnect from the NetScaler VPX
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion End NetScaler NITRO Session
