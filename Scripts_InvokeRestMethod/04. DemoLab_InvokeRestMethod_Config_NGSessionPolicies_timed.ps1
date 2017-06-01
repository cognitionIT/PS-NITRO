Measure-Command {

<#
.SYNOPSIS
  Configure Basic Gateway Settings on the NetScaler VPX.
.DESCRIPTION
  Configure Basic Gateway Settings on the NetScaler VPX, using the Invoke-RestMethod cmdlet for the REST API calls.
.NOTES
  Version:        1.1
  Author:         Esther Barthel, MSc
  Creation Date:  2017-05-04
  Purpose:        Created as part of the demo scripts for Citrix Synergy 2017 in Orlando

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
    $NSIP = ($SubnetIP + ".2")
    # Build my own credentials variable, based on password string
    $PW = ConvertTo-SecureString "nsroot" -AsPlainText -Force
    $MyCreds = New-Object System.Management.Automation.PSCredential ("nsroot", $PW)
    $FileRoot = "C:\GitHub\PS-NITRO\Scripts_InvokeRestMethod"

    $NSUserName = "nsroot"
    $NSUserPW = "nsroot"

    $strDate = Get-Date -Format yyyyMMddHHmmss
#endregion NITRO settings

Write-Host "------------------------------------------------------------------ " -ForegroundColor Yellow
Write-Host "| Pushing the Gateway configuration to NetScaler with NITRO:     | " -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------ " -ForegroundColor Yellow

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
    # enable ns feature VPN

    $payload = @{
    "nsfeature"= @{
        "feature"=@("SSLVPN")
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Enable NetScaler Basic & Advanced Features

# ----------------------------------------------
# | Add VPN Session Profile - Receiver for Web |
# ----------------------------------------------
#region Add VPN Session Action - Receiver for Web
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/vpnsessionaction"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add vpn sessionAction WB_prof -transparentInterception OFF -defaultAuthorizationAction ALLOW -SSO ON -ssoCredential PRIMARY -homePage "https://sf.demo.lab/Citrix/StoreWeb" -icaProxy ON -wihome "https://sf.demo.lab/Citrix/StoreWeb" -ntDomain DEMO 

    $payload = @{
    "vpnsessionaction"= @{
        "name"="AC_WB_Receiver";
    # If you are using the NetScaler Gateway Plug-in for Windows, set this parameter to ON, in which the mode is set to transparent. If you are using the NetScaler Gateway Plug-in for Java, set this parameter to OFF.
        "transparentinterception"="OFF";
    # Specify the network resources that users have access to when they log on to the internal network.
        "defaultauthorizationaction" = "ALLOW";
        "sso" = "ON";
        "ssocredential" = "PRIMARY";
        "homepage" = "https://storefront.demo.lab/Citrix/StoreWeb";
        "icaproxy" = "ON";
        "wihome" = "https://storefront.demo.lab/Citrix/StoreWeb";
        "ntdomain" = "DEMO";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add VPN Session Profile - Receiver for Web

# ---------------------------------------------
# | Add VPN Session Policy - Receiver for Web |
# ---------------------------------------------
#region Add VPN Session Policy - Receiver for Web
<#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/vpnsessionpolicy
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"vpnsessionpolicy":{
          "name":<String_value>,
          "rule":<String_value>,
          "action":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/vpnsessionpolicy"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    #add vpn sessionPolicy WB_pol "REQ.HTTP.HEADER User-Agent NOTCONTAINS CitrixReceiver && REQ.HTTP.HEADER Referer EXISTS" WB_prof

    $payload = @{
    "vpnsessionpolicy"= @{
        "name" = "PL_WB_Receiver";
        "rule" = "REQ.HTTP.HEADER User-Agent NOTCONTAINS CitrixReceiver && REQ.HTTP.HEADER Referer EXISTS";
        "action" = "AC_WB_Receiver";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add VPN Session Policy - Receiver for Web

# ---------------------------------------------
# | Add VPN Session Profile - Native Receiver |
# ---------------------------------------------
#region Add VPN Session Action - Native Receiver
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/vpnsessionaction"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add vpn sessionAction OS_prof -transparentInterception OFF -defaultAuthorizationAction ALLOW -SSO ON -ssoCredential PRIMARY -icaProxy ON -wihome "https://sf.demo.lab/Citrix/Store" -ntDomain DEMO -storefronturl "https://sf.demo.lab"

    $payload = @{
    "vpnsessionaction"= @{
        "name"="AC_OS_Receiver";
    # If you are using the NetScaler Gateway Plug-in for Windows, set this parameter to ON, in which the mode is set to transparent. If you are using the NetScaler Gateway Plug-in for Java, set this parameter to OFF.
        "transparentinterception"="OFF";
    # Specify the network resources that users have access to when they log on to the internal network.
        "defaultauthorizationaction" = "ALLOW";
        "sso" = "ON";
        "ssocredential" = "PRIMARY";
        "icaproxy" = "ON";
        "wihome" = "https://storefront.demo.lab/Citrix/Store";
        "ntdomain" = "DEMO";
    # Web address for StoreFront to be used in this session for enumeration of resources from XenApp or XenDesktop. (Account Services Address)
        "storefronturl" = "https://storefront.demo.lab";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add VPN Session Profile - Native Receiver

# --------------------------------------------
# | Add VPN Session Policy - Native Receiver |
# --------------------------------------------
#region Add VPN Session Policy - Native Receiver
<#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/vpnsessionpolicy
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"vpnsessionpolicy":{
          "name":<String_value>,
          "rule":<String_value>,
          "action":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>

    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/vpnsessionpolicy"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    #add vpn sessionPolicy OS_pol "REQ.HTTP.HEADER User-Agent CONTAINS CitrixReceiver" OS_prof

    $payload = @{
    "vpnsessionpolicy"= @{
        "name" = "PL_OS_Receiver";
        "rule" = "REQ.HTTP.HEADER User-Agent CONTAINS CitrixReceiver";
        "action" = "AC_OS_Receiver";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add VPN Session Policy - Native Receiver

# --------------------------------------------
# | Add NSG vServer                          |
# --------------------------------------------
#region Add VPN vServer
<#
    add
    URL:http://<netscaler-ip-address>/nitro/v1/config/vpnvserver
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"vpnvserver":{
          "name":<String_value>,
          "servicetype":<String_value>,
          "ipv46":<String_value>,
          "range":<Double_value>,
          "port":<Integer_value>,
          "state":<String_value>,
          "authentication":<String_value>,
          "doublehop":<String_value>,
          "maxaaausers":<Double_value>,
          "icaonly":<String_value>,
          "icaproxysessionmigration":<String_value>,
          "dtls":<String_value>,
          "loginonce":<String_value>,
          "advancedepa":<String_value>,
          "devicecert":<String_value>,
          "certkeynames":<String_value>,
          "downstateflush":<String_value>,
          "listenpolicy":<String_value>,
          "listenpriority":<Double_value>,
          "tcpprofilename":<String_value>,
          "httpprofilename":<String_value>,
          "comment":<String_value>,
          "appflowlog":<String_value>,
          "icmpvsrresponse":<String_value>,
          "rhistate":<String_value>,
          "netprofile":<String_value>,
          "cginfrahomepageredirect":<String_value>,
          "maxloginattempts":<Double_value>,
          "failedlogintimeout":<Double_value>,
          "l2conn":<String_value>,
          "deploymenttype":<String_value>,
          "rdpserverprofilename":<String_value>,
          "windowsepapluginupgrade":<String_value>,
          "linuxepapluginupgrade":<String_value>,
          "macepapluginupgrade":<String_value>,
          "userdomains":<String_value>,
          "authnprofile":<String_value>,
          "vserverfqdn":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/vpnvserver"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add vpn vserver test SSL 192.168.59.102 443 -maxAAAUsers 50 -icaOnly ON -downStateFlush DISABLED -Listenpolicy NONE

    $payload = @{
        "vpnvserver"= @{
          "name"="vsvr_nsg_demo_lab";
          "servicetype"="SSL";
          "ipv46"=($SubnetIP + ".9");
          "port"=443;
          "state"="ENABLED";
          "maxaaausers"=50;
          "icaonly"="ON";
          "downstateflush"="DISABLED";
          "listenpolicy"="NONE";
          "comment"="created by PowerShell script";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add VPN vServer


# --------------------------------------------
# | Bind VPN Session Policies to VPN vServer |
# --------------------------------------------
#region Bind VPN Session Policies to VPN vServer (bulk)
<#
    add:
    URL:http://<netscaler-ip-address/nitro/v1/config/vpnvserver_vpnsessionpolicy_binding
    HTTP Method:PUT
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {
    "vpnvserver_vpnsessionpolicy_binding":{
          "name":<String_value>,
          "policy":<String_value>,
          "priority":<Double_value>,
          "secondary":<Boolean_value>,
          "groupextraction":<Boolean_value>,
          "gotopriorityexpression":<String_value>,
          "bindpoint":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>

    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/vpnvserver_vpnsessionpolicy_binding"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    #bind vpn vserver vsvr_nsg_demo_lab -policy OS_pol -priority 100

    $payload = @{
        "vpnvserver_vpnsessionpolicy_binding"= @(
            @{"name"="vsvr_nsg_demo_lab";"policy"="PL_WB_Receiver";"priority"=100},
            @{"name"="vsvr_nsg_demo_lab";"policy"="PL_OS_Receiver";"priority"=110}
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Uri $strURI -Method Put -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind VPN Session Policies to VPN vServer


# ---------------------------------------
# | Bind VPN STA servers to VPN vServer |
# ---------------------------------------
#region Bind VPN STA servers to VPN vServer
<#
    add:
    URL:http://<netscaler-ip-address/nitro/v1/config/vpnvserver_staserver_binding
    HTTP Method:PUT
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {
    "vpnvserver_staserver_binding":{
          "name":<String_value>,
          "staserver":<String_value>,
          "staaddresstype":<String_value>
    }}
    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>

    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/vpnvserver_staserver_binding"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    #bind vpn vserver vsvr_nsg_demo_lab -staServer "http://192.168.0.25"

    $payload = @{
        "vpnvserver_staserver_binding"= @(
            @{"name" = "vsvr_nsg_demo_lab"; "staserver" = ("http://xd001.demo.local"); "staaddresstype" = "IPV4"}
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Uri $strURI -Method Put -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind VPN STA servers to VPN vServer

# ---------------------------------------
# | Bind SSL certificate to VPN vServer |
# ---------------------------------------
#region Bind SSL certificate to VPN vServer
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

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    #bind ssl vserver vsvr_nsg_demo_lab -certkeyName wildcard.demo.lab

    $payload = @{
    "sslvserver_sslcertkey_binding"= @{
        "vservername" = "vsvr_nsg_demo_lab";
        "certkeyname" = "wildcard.demo.lab"
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Uri $strURI -Method Put -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind SSL certificate to VPN vServer

# ------------------------------------
# | Bind Portal Theme to VPN vServer |
# ------------------------------------
#region Bind portal theme to VPN vServer
<#
    add:
    URL: http://<netscaler-ip-address/nitro/v1/config/vpnvserver_vpnportaltheme_binding
    HTTP Method: PUT
    Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
    Request Payload: 
    {
    "vpnvserver_vpnportaltheme_binding":{
          "name":<String_value>,
          "portaltheme":<String_value>
    }}

    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>

    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/vpnvserver_vpnportaltheme_binding"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # bind vpn vserver vsvr_nsg_demo_lab -portaltheme X1

    $payload = @{
    "vpnvserver_vpnportaltheme_binding"= @{
          "name"="vsvr_nsg_demo_lab";
          "portaltheme"="X1";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Uri $strURI -Method Put -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind portal theme to VPN vServer

# --------------------------------------------
# | Configure and Bind LDAP Server           |
# --------------------------------------------
#region Add LDAP Server
<#
    add
        URL: http://<netscaler-ip-address>/nitro/v1/config/authenticationldapaction
    HTTP Method: POST
    Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
    Request Payload: 
    {"authenticationldapaction":{
          "name":<String_value>,
          "serverip":<String_value>,
          "servername":<String_value>,
          "serverport":<Integer_value>,
          "authtimeout":<Double_value>,
          "ldapbase":<String_value>,
          "ldapbinddn":<String_value>,
          "ldapbinddnpassword":<String_value>,
          "ldaploginname":<String_value>,
          "searchfilter":<String_value>,
          "groupattrname":<String_value>,
          "subattributename":<String_value>,
          "sectype":<String_value>,
          "svrtype":<String_value>,
          "ssonameattribute":<String_value>,
          "authentication":<String_value>,
          "requireuser":<String_value>,
          "passwdchange":<String_value>,
          "nestedgroupextraction":<String_value>,
          "maxnestinglevel":<Double_value>,
          "followreferrals":<String_value>,
          "maxldapreferrals":<Double_value>,
          "referraldnslookup":<String_value>,
          "mssrvrecordlocation":<String_value>,
          "validateservercert":<String_value>,
          "ldaphostname":<String_value>,
          "groupnameidentifier":<String_value>,
          "groupsearchattribute":<String_value>,
          "groupsearchsubattribute":<String_value>,
          "groupsearchfilter":<String_value>,
          "defaultauthenticationgroup":<String_value>,
          "attribute1":<String_value>,
          "attribute2":<String_value>,
          "attribute3":<String_value>,
          "attribute4":<String_value>,
          "attribute5":<String_value>,
          "attribute6":<String_value>,
          "attribute7":<String_value>,
          "attribute8":<String_value>,
          "attribute9":<String_value>,
          "attribute10":<String_value>,
          "attribute11":<String_value>,
          "attribute12":<String_value>,
          "attribute13":<String_value>,
          "attribute14":<String_value>,
          "attribute15":<String_value>,
          "attribute16":<String_value>
    }}

    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors).
#>

    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/authenticationldapaction"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add authentication ldapAction dc001_LDAP_svr -serverIP 192.168.59.10 -ldapBase "DC=demo,DC=local" -ldapBindDn administrator@demo.lab -ldapLoginName sAMAccountName

    $payload = @{
        "authenticationldapaction"= @{
            "name"="svr_ldap_dc001";
            "serverip"=($SubnetIP + ".100");
            "serverport"=389;
            "ldapbase"="DC=demo,DC=local"
            "ldapbinddn"="svc_LDAPQueries";
            "ldapbinddnpassword"="Welcome01";
            "ldaploginname"="sAMAccountName";
            "ssonameattribute"="userPrincipalName";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add LDAP Server

#region Add LDAP Policy
<#
    add
        URL: http://<netscaler-ip-address>/nitro/v1/config/authenticationldappolicy
    HTTP Method: POST
    Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
    Request Payload: 
    {"authenticationldappolicy":{
          "name":<String_value>,
          "rule":<String_value>,
          "reqaction":<String_value>
    }}

    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/authenticationldappolicy"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add authentication ldapPolicy Demo_LDAP_pol ns_true dc001_LDAP_svr

    $payload = @{
        "authenticationldappolicy"= @{
                "name"="pol_LDAP_dc001";
                "rule"="ns_true";
                "reqaction"="svr_ldap_dc001";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add LDAP Policy

#region Bind LDAP Policy to vServer
<#
    add:
    URL: http://<netscaler-ip-address/nitro/v1/config/vpnvserver_authenticationldappolicy_binding
    HTTP Method: PUT
    Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
    Request Payload: 
    {"vpnvserver_authenticationldappolicy_binding":{
          "name":<String_value>,
          "policy":<String_value>,
          "priority":<Double_value>,
          "secondary":<Boolean_value>,
          "groupextraction":<Boolean_value>,
          "gotopriorityexpression":<String_value>,
          "bindpoint":<String_value>
    }}

    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/vpnvserver_authenticationldappolicy_binding"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # bind vpn vserver vsvr_nsg_demo_lab -policy Demo_LDAP_pol -priority 100

    $payload = @{
        "vpnvserver_authenticationldappolicy_binding"= @{
                "name"="vsvr_nsg_demo_lab";
                "policy"="pol_LDAP_dc001";
                "priority"=100;
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind LDAP Policy to vServer


#region End NetScaler NITRO Session

    # -------------------------------------
    # | Add DNS Address Records           |
    # -------------------------------------
    #region Add DNS Address Records (bulk)
    <#
        add
        URL: http://<netscaler-ip-address>/nitro/v1/config/dnsaddrec
        HTTP Method: POST
        Request Headers:
            Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
            Content-Type:application/json
        Request Payload: 
        {"dnsaddrec":{
              "hostname":<String_value>,
              "ipaddress":<String_value>,
              "ttl":<Double_value>
        }}

        Response:
        HTTP Status Code on Success: 201 Created
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
        # Specifying the correct URL 
        $strURI = "http://$NSIP/nitro/v1/config/dnsaddrec"

        # Creating the right payload formatting (mind the Depth for the nested arrays)
        # add dns addRec storefront.demo.lab 192.168.0.102
        # add dns addRec xd001.demo.local 192.168.0.102

        $payload = @{
            "dnsaddrec"= @(
                @{"hostname"="storefront.demo.lab";"ipaddress"="192.168.0.102";"ttl"=3600},
                @{"hostname"="xd001.demo.local";"ipaddress"="192.168.0.102";"ttl"=3600}
            )
        } | ConvertTo-Json -Depth 5

        # Logging NetScaler Instance payload formatting
#        Write-Host "payload: " -ForegroundColor Yellow
#        Write-Host $payload -ForegroundColor Green

        # Method #1: Making the REST API call to the NetScaler
        $response = Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    #endregion Add DNS Address Records

    #Disconnect from the NetScaler VPX
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session

}