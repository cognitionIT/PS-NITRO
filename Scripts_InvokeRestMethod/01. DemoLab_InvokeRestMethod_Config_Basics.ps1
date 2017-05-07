<#
.SYNOPSIS
  Configure Basic System Settings on the NetScaler VPX.
.DESCRIPTION
  Configure Basic System Settings (First Logon Wizard, Modes, Features) on the NetScaler VPX, using the Invoke-RestMethod cmdlet for the REST API calls.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-05-04
  Purpose:        Created as part of the demo scripts for the PowerShell Conference EU 2017 in Hannover

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

Write-Host "------------------------------------------------------------------ " -ForegroundColor Yellow
Write-Host "| Pushing the first Logon configuration to NetScaler with NITRO: | " -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------ " -ForegroundColor Yellow

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

# -------------------------------
# | First Logon (Wizard) config |
# -------------------------------

#region First GUI logon to NetScaler Management Console asks for:
    #region Step 0: Disable Citrix User Experience Improvement Program (CUXIP)
    <#
        update
        URL:http://<netscaler-ip-address>/nitro/v1/config/systemparameter
        HTTP Method:PUT
        Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
        Request Payload:
        {"systemparameter":{
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
                "totalauthtimeout":<Double_value>,
                "cliloglevel":<String_value>
        }}
        Response:
        HTTP Status Code on Success: 200 OK
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
        # Specifying the correct URL 
        $strURI = "http://$NSIP/nitro/v1/config/systemparameter"

        # Creating the right payload formatting (mind the Depth for the nested arrays)
        # set system parameter -doppler DISABLED

        $payload = @{
        "systemparameter"= @{
            "doppler"="DISABLED";
            }
        } | ConvertTo-Json -Depth 5

        # Logging NetScaler Instance payload formatting
        Write-Host "payload: " -ForegroundColor Yellow
        Write-Host $payload -ForegroundColor Green

        # Method #1: Making the REST API call to the NetScaler
        $dummy = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
    #endregion Disable Citrix User Experience Improvement Program (CUXIP)

    #region Step 2: Add SNIP
    <#
        add
        URL:http://<netscaler-ip-address>/nitro/v1/config/nsip
        HTTP Method:POST
        Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
        Request Payload:
        {"nsip":{
                "ipaddress":<String_value>,
                "netmask":<String_value>,
                "type":<String_value>,
                "arp":<String_value>,
                "icmp":<String_value>,
                "vserver":<String_value>,
                "telnet":<String_value>,
                "ftp":<String_value>,
                "gui":<String_value>,
                "ssh":<String_value>,
                "snmp":<String_value>,
                "mgmtaccess":<String_value>,
                "restrictaccess":<String_value>,
                "dynamicrouting":<String_value>,
                "ospf":<String_value>,
                "bgp":<String_value>,
                "rip":<String_value>,
                "hostroute":<String_value>,
                "hostrtgw":<String_value>,
                "metric":<Integer_value>,
                "vserverrhilevel":<String_value>,
                "vserverrhimode":<String_value>,
                "ospflsatype":<String_value>,
                "ospfarea":<Double_value>,
                "state":<String_value>,
                "vrid":<Double_value>,
                "icmpresponse":<String_value>,
                "ownernode":<Double_value>,
                "arpresponse":<String_value>,
                "td":<Double_value>
        }}
        Response:
        HTTP Status Code on Success: 201 Created
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
        # Specifying the correct URL 
        $strURI = "http://$NSIP/nitro/v1/config/nsip"

        # Creating the right payload formatting (mind the Depth for the nested arrays)
        # add ns ip 192.168.59.3 255.255.255.0 -vServer DISABLED

        $payload = @{
        "nsip"= @{
            "ipaddress"=($SubNetIP + ".3");
            "netmask"="255.255.255.0";
            "type"="SNIP";
            }
        } | ConvertTo-Json -Depth 5

        # Logging NetScaler Instance payload formatting
        Write-Host "payload: " -ForegroundColor Yellow
        Write-Host $payload -ForegroundColor Green

        # Method #1: Making the REST API call to the NetScaler
        $dummy = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorVariable restError -ErrorAction SilentlyContinue
    #endregion Add SNIP

    #region Step 3a: Add Hostname
    <#
        update
        URL:http://<netscaler-ip-address>/nitro/v1/config/nshostname
        HTTP Method:PUT
        Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
        Request Payload:
        {"nshostname":{
              "hostname":<String_value>,
              "ownernode":<Double_value>
        }}
        Response:
        HTTP Status Code on Success: 200 OK
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
        # Specifying the correct URL 
        $strURI = "http://$NSIP/nitro/v1/config/nshostname"

        # Creating the right payload formatting (mind the Depth for the nested arrays)
        # set ns hostName NSNitroDemo

        $payload = @{
        "nshostname"= @{
            "hostname"="NSNitroDemo";
            }
        } | ConvertTo-Json -Depth 5

        # Logging NetScaler Instance payload formatting
        Write-Host "payload: " -ForegroundColor Yellow
        Write-Host $payload -ForegroundColor Green

        # Method #1: Making the REST API call to the NetScaler
        $dummy = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
    #endregion Add Hostname

    #region Step 3b: Add DNS Server
    <#
        add
        URL:http://<netscaler-ip-address>/nitro/v1/config/dnsnameserver
        HTTP Method:POST
        Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
        Request Payload:
        {"dnsnameserver":{
              "ip":<String_value>,
              "dnsvservername":<String_value>,
              "local":<Boolean_value>,
              "state":<String_value>,
              "type":<String_value>,
              "dnsprofilename":<String_value>
        }}
        Response:
        HTTP Status Code on Success: 201 Created
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
        # Specifying the correct URL 
        $strURI = "http://$NSIP/nitro/v1/config/dnsnameserver"

        # Creating the right payload formatting (mind the Depth for the nested arrays)
        # add dns nameServer 192.168.59.1

        $payload = @{
        "dnsnameserver"= @{
            "ip"=($SubNetIP + ".1");
            }
        } | ConvertTo-Json -Depth 5

        # Logging NetScaler Instance payload formatting
        Write-Host "payload: " -ForegroundColor Yellow
        Write-Host $payload -ForegroundColor Green

        # Method #1: Making the REST API call to the NetScaler
        $dummy = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
    #endregion Add DNS Server

    #region Step 3c: Set Timezone
    <#
        update
        URL:http://<netscaler-ip-address>/nitro/v1/config/nsconfig
        HTTP Method:PUT
        Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
        Request Payload:
        {"nsconfig":{
              "ipaddress":<String_value>,
              "netmask":<String_value>,
              "nsvlan":<Double_value>,
              "ifnum":<String[]_value>,
              "tagged":<String_value>,
              "httpport":<Integer[]_value>,
              "maxconn":<Double_value>,
              "maxreq":<Double_value>,
              "cip":<String_value>,
              "cipheader":<String_value>,
              "cookieversion":<String_value>,
              "securecookie":<String_value>,
              "pmtumin":<Double_value>,
              "pmtutimeout":<Double_value>,
              "ftpportrange":<String_value>,
              "crportrange":<String_value>,
              "timezone":<String_value>,
              "grantquotamaxclient":<Double_value>,
              "exclusivequotamaxclient":<Double_value>,
              "grantquotaspillover":<Double_value>,
              "exclusivequotaspillover":<Double_value>
        }}
        Response:
        HTTP Status Code on Success: 200 OK
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
        # Specifying the correct URL 
        $strURI = "http://$NSIP/nitro/v1/config/nsconfig"

        # Creating the right payload formatting (mind the Depth for the nested arrays)
        # set ns param -timezone "GMT+01:00-CET-Europe/Amsterdam"

        $payload = @{
        "nsconfig"= @{
            "timezone"="GMT+01:00-CET-Europe/Amsterdam";
            }
        } | ConvertTo-Json -Depth 5

        # Logging NetScaler Instance payload formatting
        Write-Host "payload: " -ForegroundColor Yellow
        Write-Host $payload -ForegroundColor Green

        # Method #1: Making the REST API call to the NetScaler
        $dummy = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
    #endregion Set Timezone

    #region Step 4: Get License Info
    <#
        get (all)
        URL:http://<netscaler-ip-address>/nitro/v1/config/nslicense
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
        { "nslicense": [ {
              "wl":<Boolean_value>,
              "sp":<Boolean_value>,
              "lb":<Boolean_value>,
              "cs":<Boolean_value>,
              "cr":<Boolean_value>,
              "sc":<Boolean_value>,
              "cmp":<Boolean_value>,
              "delta":<Boolean_value>,
              "pq":<Boolean_value>,
              "ssl":<Boolean_value>,
              "gslb":<Boolean_value>,
              "gslbp":<Boolean_value>,
              "hdosp":<Boolean_value>,
              "routing":<Boolean_value>,
              "cf":<Boolean_value>,
              "contentaccelerator":<Boolean_value>,
              "ic":<Boolean_value>,
              "sslvpn":<Boolean_value>,
              "f_sslvpn_users":<Double_value>,
              "f_ica_users":<Double_value>,
              "aaa":<Boolean_value>,
              "ospf":<Boolean_value>,
              "rip":<Boolean_value>,
              "bgp":<Boolean_value>,
              "rewrite":<Boolean_value>,
              "ipv6pt":<Boolean_value>,
              "appfw":<Boolean_value>,
              "responder":<Boolean_value>,
              "agee":<Boolean_value>,
              "nsxn":<Boolean_value>,
              "htmlinjection":<Boolean_value>,
              "modelid":<Double_value>,
              "push":<Boolean_value>,
              "wionns":<Boolean_value>,
              "appflow":<Boolean_value>,
              "cloudbridge":<Boolean_value>,
              "cloudbridgeappliance":<Boolean_value>,
              "cloudextenderappliance":<Boolean_value>,
              "isis":<Boolean_value>,
              "cluster":<Boolean_value>,
              "ch":<Boolean_value>,
              "appqoe":<Boolean_value>,
              "appflowica":<Boolean_value>,
              "isstandardlic":<Boolean_value>,
              "isenterpriselic":<Boolean_value>,
              "isplatinumlic":<Boolean_value>,
              "issgwylic":<Boolean_value>,
              "rise":<Boolean_value>,
              "vpath":<Boolean_value>,
              "feo":<Boolean_value>,
              "lsn":<Boolean_value>,
              "ispooledlicensing":<String_value>,
              "rdpproxy":<Boolean_value>,
              "rep":<Boolean_value>
        }]}
    #>
        # Specifying the correct URL 
        $strURI = "http://$NSIP/nitro/v1/config/nslicense"

        # Method #1: Making the REST API call to the NetScaler
        $LicInfo = (Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue).nslicense
        Write-Host ("`nLicense info: `n-------------`n`tmodel ID = " + $LicInfo.modelid + "; Standard License = " + $LicInfo.isstandardlic + "; Enterprise License = " + $LicInfo.isenterpriselic + "; Platinum License = " + $LicInfo.isplatinumlic + "`n") -ForegroundColor Magenta
    #endregion Get License Info
#endregion

#region End NetScaler NITRO Session
    #Disconnect from the NetScaler VPX
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session

Write-Host "------------------------------------------------------------ " -ForegroundColor Yellow
Write-Host "| Pushing the Basic configuration to NetScaler with NITRO: | " -ForegroundColor Yellow
Write-Host "------------------------------------------------------------ " -ForegroundColor Yellow

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


# -----------------------------------
# | NetScaler Basic System Settings |
# -----------------------------------

#region Enable NetScaler Modes
<#
    enable
    URL:http://<netscaler-ip-address>/nitro/v1/config/nsmode?action=enable
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"nsmode":{
          "mode":<String[]_value>
    }}
    Response:
    HTTP Status Code on Success: 200 OK
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/nsmode?action=enable"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # enable ns mode FR L3 Edge USNIP PMTUD

    $payload = @{
    "nsmode"= @{
        "mode"=@("FR","Edge","L3","USNIP","PMTUD")
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $dummy = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion Enable NetScaler Modes

#region Disable NetScaler Feature (Call Home)
<#
    disable
    URL:http://<netscaler-ip-address>/nitro/v1/config/nsfeature?action=disable
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
    Request Payload:
    {"nsfeature":{
          "feature":<String[]_value>
    }}
    Response:
    HTTP Status Code on Success: 200 OK
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/nsfeature?action=disable"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # disable ns feature CH

    $payload = @{
    "nsfeature"= @{
        "feature"=@("CH")
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $dummy = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion Disable NetScaler Modes

#region Enable NetScaler Basic & Advanced Features
<#
    enable
    URL:http://<netscaler-ip-address>/nitro/v1/config/nsfeature?action=enable
    HTTP Method:POST
    Request Headers:
    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
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

    $payload = @{
    "nsfeature"= @{
        "feature"=@("LB","SSL","SSLVPN","REWRITE","RESPONDER")
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $dummy = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion Enable NetScaler Basic & Advanced Features


#region End NetScaler NITRO Session
    #Disconnect from the NetScaler VPX
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session
