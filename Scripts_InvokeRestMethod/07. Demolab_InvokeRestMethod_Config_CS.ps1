<#
.SYNOPSIS
  Configure Basic Content Switching on the NetScaler VPX.
.DESCRIPTION
  Configure Basic Content Switching on the NetScaler VPX, using the Invoke-RestMethod cmdlet for the REST API calls.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-07-26
  Purpose:        Created to quickly test CS supporting configs

  Copyright (c) cognition IT. All rights reserved.
#>

#region NITRO settings
    #region Test Environment variables
        $TestEnvironment = "demo"

        Switch ($TestEnvironment)
        {
            "Elektra" 
            {
                $RootFolder = "H:\PSModules\NITRO\Scripts"
                $SubnetIP = "192.168.59"
            }
            default
            {
                $RootFolder = "C:\Scripts\NITRO"
                $SubnetIP = "192.168.0"
            }
        }
        $NSLicFile = $RootFolder + "\NSVPX-ESX_PLT_201609.lic"

        # What to install (for script testing purposes)
        $ConfigNSGSettings = $true
    #endregion Test Environment variables
    $ContentType = "application/json"
    $NSIP = $SubNetIP + ".2"
    # Build my own credentials variable, based on password string
    $PW = ConvertTo-SecureString "nsroot" -AsPlainText -Force
    $MyCreds = New-Object System.Management.Automation.PSCredential ("nsroot", $PW)
#    $FileRoot = "C:\GitHub\PS-NITRO_v20170509\Scripts_InvokeRestMethod"
    $FileRoot = "C:\GitHub\PS-NITRO\Scripts_InvokeRestMethod"

    $NSUserName = "nsroot"
    $NSUserPW = "nsroot"

    $strDate = Get-Date -Format yyyyMMddHHmmss
#endregion NITRO settings

Write-Host "-------------------------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Pushing the CS configuration for NetScaler with NITRO:     | " -ForegroundColor Yellow
Write-Host "-------------------------------------------------------------- " -ForegroundColor Yellow

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
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/login" -Body $Login -Method POST -SessionVariable NetScalerSession -ContentType $ContentType -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion Start NetScaler NITRO Session

# -------------------------------------
# | Enable require NetScaler Features |
# -------------------------------------
#region Enable NetScaler Basic & Advanced Features
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/nsfeature?action=enable"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # enable ns feature CS GSLB

    $payload = @{
    "nsfeature"= @{
        "feature"=@("CS")
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Enable NetScaler Basic & Advanced Features


#source: http://bretty.me.uk/citrix-netscaler-and-content-switching-setup-guide-single-ip-address-woes/

#region Add CS vServer
    <#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/csvserver
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"csvserver":{
          "name":<String_value>,
          "td":<Double_value>,
          "servicetype":<String_value>,
          "ipv46":<String_value>,
          "targettype":<String_value>,
          "dnsrecordtype":<String_value>,
          "persistenceid":<Double_value>,
          "ippattern":<String_value>,
          "ipmask":<String_value>,
          "range":<Double_value>,
          "port":<Integer_value>,
          "state":<String_value>,
          "stateupdate":<String_value>,
          "cacheable":<String_value>,
          "redirecturl":<String_value>,
          "clttimeout":<Double_value>,
          "precedence":<String_value>,
          "casesensitive":<String_value>,
          "somethod":<String_value>,
          "sopersistence":<String_value>,
          "sopersistencetimeout":<Double_value>,
          "sothreshold":<Double_value>,
          "sobackupaction":<String_value>,
          "redirectportrewrite":<String_value>,
          "downstateflush":<String_value>,
          "backupvserver":<String_value>,
          "disableprimaryondown":<String_value>,
          "insertvserveripport":<String_value>,
          "vipheader":<String_value>,
          "rtspnat":<String_value>,
          "authenticationhost":<String_value>,
          "authentication":<String_value>,
          "listenpolicy":<String_value>,
          "listenpriority":<Double_value>,
          "authn401":<String_value>,
          "authnvsname":<String_value>,
          "push":<String_value>,
          "pushvserver":<String_value>,
          "pushlabel":<String_value>,
          "pushmulticlients":<String_value>,
          "tcpprofilename":<String_value>,
          "httpprofilename":<String_value>,
          "dbprofilename":<String_value>,
          "oracleserverversion":<String_value>,
          "comment":<String_value>,
          "mssqlserverversion":<String_value>,
          "l2conn":<String_value>,
          "mysqlprotocolversion":<Double_value>,
          "mysqlserverversion":<String_value>,
          "mysqlcharacterset":<Double_value>,
          "mysqlservercapabilities":<Double_value>,
          "appflowlog":<String_value>,
          "netprofile":<String_value>,
          "icmpvsrresponse":<String_value>,
          "rhistate":<String_value>,
          "authnprofile":<String_value>,
          "dnsprofilename":<String_value>
    }}

    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/csvserver"

    # add cs vserver cs_vsvr_one_url_test SSL 192.168.0.13 443 -cltTimeout 180
    $payload = @{
        "csvserver"= @{
            "name"="cs_vsvr_one_url_test"; 
            "servicetype"="SSL"; 
            "ipv46"="192.168.0.13";
            "port"=443;
            "clttimeout"=180;
            "comment"="created with powershell";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add CS Actions

#region Add CS Actions (bulk)
    <#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/csaction
    HTTP Method:POST
    Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json

    Request Payload:
    {"csaction":{
          "name":<String_value>,
          "targetlbvserver":<String_value>,
          "targetvserver":<String_value>,
          "targetvserverexpr":<String_value>,
          "comment":<String_value>
    }}

    Response:

    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/csaction"

    # add cs action cs_action_gateway -targetVserver vsvr_nsg_demo_lab
    # add cs action cs_action_storefront -targetLBVserver vsvr_SFStore
    $payload = @{
        "csaction"= @(
            @{"name"="cs_act_gateway"; "targetvserver"="vsvr_nsg_demo_lab"; "comment"="created with powershell"},
            @{"name"="cs_act_storefront"; "targetlbvserver"="vsvr_SFStore"; "comment"="created with powershell"}
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add CS Actions

#region Add CS Policies (bulk)
    <#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/cspolicy
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"cspolicy":{
          "policyname":<String_value>,
          "url":<String_value>,
          "rule":<String_value>,
          "domain":<String_value>,
          "action":<String_value>,
          "logaction":<String_value>
    }}

    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/cspolicy"

    # add cs policy cs_pol_gateway -rule "HTTP.REQ.HOSTNAME.SET_TEXT_MODE(IGNORECASE).EQ(\"nsg.demo.lab\")" -action cs_action_gateway
    # add cs policy cs_pol_storefront -rule "HTTP.REQ.HOSTNAME.SET_TEXT_MODE(IGNORECASE).EQ(\"sf.demo.lab\")" -action cs_action_storefront
    $payload = @{
        "cspolicy"= @(
            @{"policyname"="cs_pol_gateway"; "rule"="HTTP.REQ.HOSTNAME.SET_TEXT_MODE(IGNORECASE).EQ(""nsg.demo.lab"")"; "action"="cs_act_gateway"},
            @{"policyname"="cs_pol_storefront"; "rule"="HTTP.REQ.HOSTNAME.SET_TEXT_MODE(IGNORECASE).EQ(""sf.demo.lab"")"; "action"="cs_act_storefront"}
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add CS Policies

#region Bind CS Policies to vServer(bulk)
    <#
    add:
    URL:http://<netscaler-ip-address/nitro/v1/config/csvserver_cspolicy_binding
    HTTP Method:PUT

    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json

    Request Payload:
    {
    "csvserver_cspolicy_binding":{
          "name":<String_value>,
          "policyname":<String_value>,
          "targetlbvserver":<String_value>,
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
    $strURI = "http://$NSIP/nitro/v1/config/csvserver_cspolicy_binding"

    # bind cs vserver cs_vsvr_one_url_test -policyName cs_pol_gateway -priority 100
    # bind cs vserver cs_vsvr_one_url_test -policyName cs_pol_storefront -priority 110
    $payload = @{
        "csvserver_cspolicy_binding"= @(
            @{"name"="cs_vsvr_one_url_test"; "policyname"="cs_pol_gateway"; "priority"=100},
            @{"name"="cs_vsvr_one_url_test"; "policyname"="cs_pol_storefront"; "priority"=110}
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind CS Policies to vServer

#region Bind Certificate to vServer
    <#
        add:
        URL:http://<netscaler-ip-address/nitro/v1/config/sslvserver_sslcertkey_binding
        HTTP Method:PUT
        Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
        Request Payload:
        {
        "sslvserver_sslcertkey_binding":{
              "vservername":<String_value>,
              "certkeyname":<String_value>,
              "ca":<Boolean_value>,
              "crlcheck":<String_value>,
              "skipcaname":<Boolean_value>,
              "snicert":<Boolean_value>,
              "ocspcheck":<String_value>
        }}
        Response:
        HTTP Status Code on Success: 201 Created
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/sslvserver_sslcertkey_binding"

    # bind ssl vserver vsvr_SFStore -certkeyName wildcard.demo.lab
    $payload = @{
    "sslvserver_sslcertkey_binding"= @{
        "vservername"="cs_vsvr_one_url_test";
        "certkeyname"="wildcard.demo.lab";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind Certificate to VServer

#region Add CS vServer for HTTP to HTTPS redirection
    <#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/csvserver
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"csvserver":{
          "name":<String_value>,
          "td":<Double_value>,
          "servicetype":<String_value>,
          "ipv46":<String_value>,
          "targettype":<String_value>,
          "dnsrecordtype":<String_value>,
          "persistenceid":<Double_value>,
          "ippattern":<String_value>,
          "ipmask":<String_value>,
          "range":<Double_value>,
          "port":<Integer_value>,
          "state":<String_value>,
          "stateupdate":<String_value>,
          "cacheable":<String_value>,
          "redirecturl":<String_value>,
          "clttimeout":<Double_value>,
          "precedence":<String_value>,
          "casesensitive":<String_value>,
          "somethod":<String_value>,
          "sopersistence":<String_value>,
          "sopersistencetimeout":<Double_value>,
          "sothreshold":<Double_value>,
          "sobackupaction":<String_value>,
          "redirectportrewrite":<String_value>,
          "downstateflush":<String_value>,
          "backupvserver":<String_value>,
          "disableprimaryondown":<String_value>,
          "insertvserveripport":<String_value>,
          "vipheader":<String_value>,
          "rtspnat":<String_value>,
          "authenticationhost":<String_value>,
          "authentication":<String_value>,
          "listenpolicy":<String_value>,
          "listenpriority":<Double_value>,
          "authn401":<String_value>,
          "authnvsname":<String_value>,
          "push":<String_value>,
          "pushvserver":<String_value>,
          "pushlabel":<String_value>,
          "pushmulticlients":<String_value>,
          "tcpprofilename":<String_value>,
          "httpprofilename":<String_value>,
          "dbprofilename":<String_value>,
          "oracleserverversion":<String_value>,
          "comment":<String_value>,
          "mssqlserverversion":<String_value>,
          "l2conn":<String_value>,
          "mysqlprotocolversion":<Double_value>,
          "mysqlserverversion":<String_value>,
          "mysqlcharacterset":<Double_value>,
          "mysqlservercapabilities":<Double_value>,
          "appflowlog":<String_value>,
          "netprofile":<String_value>,
          "icmpvsrresponse":<String_value>,
          "rhistate":<String_value>,
          "authnprofile":<String_value>,
          "dnsprofilename":<String_value>
    }}

    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/csvserver"

    # add cs vserver cs_vsvr_http_https_redirection HTTP 192.168.0.13 80 -cltTimeout 180
    $payload = @{
        "csvserver"= @{
            "name"="cs_vsvr_http_https_redirection"; 
            "servicetype"="HTTP"; 
            "ipv46"="192.168.0.13";
            "port"=80;
            "clttimeout"=180;
            "comment"="Carsten Bruns' tip for http to https redirection best practice";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add CS Actions
#region Bind Responder Policy to CS vServer
<#
    add:
    URL:http://<netscaler-ip-address/nitro/v1/config/csvserver_responderpolicy_binding
    HTTP Method:PUT
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {
    "csvserver_responderpolicy_binding":{
          "name":<String_value>,
          "policyname":<String_value>,
          "targetlbvserver":<String_value>,
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
    $strURI = "http://$NSIP/nitro/v1/config/csvserver_responderpolicy_binding"

    # 
    $payload = @{
    "csvserver_responderpolicy_binding"= @{
          "name"="cs_vsvr_http_https_redirection";
          "policyname"="rspp_http_https_redirect";
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
#endregion Bind Responder Policy to vServer


#TODO:

<#
add cs vserver cs_vsvr_one_url_test SSL 192.168.0.13 443 -cltTimeout 180
add cs action cs_action_gateway -targetVserver vsvr_nsg_demo_lab
add cs action cs_action_storefront -targetLBVserver vsvr_SFStore
add cs policy cs_pol_gateway -rule "HTTP.REQ.HOSTNAME.SET_TEXT_MODE(IGNORECASE).EQ(\"nsg.demo.lab\")" -action cs_action_gateway
add cs policy cs_pol_storefront -rule "HTTP.REQ.HOSTNAME.SET_TEXT_MODE(IGNORECASE).EQ(\"sf.demo.lab\")" -action cs_action_storefront
bind cs vserver cs_vsvr_one_url_test -policyName cs_pol_gateway -priority 100
bind cs vserver cs_vsvr_one_url_test -policyName cs_pol_storefront -priority 110
bind ssl vserver cs_vsvr_one_url_test -certkeyName wildcard.demo.lab



#>

#region End NetScaler NITRO Session
    #Disconnect from the NetScaler VPX
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session

