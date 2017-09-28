<#
.SYNOPSIS
  Configure Best Practices for NetScaler deployments.
.DESCRIPTION
  Configure Best Practices for NetScaler deployments, using the Invoke-RestMethod cmdlet for the REST API calls.
.NOTES
  Version:        0.1
  Author:         Esther Barthel, MSc
  Creation Date:  2017-09-26
  Purpose:        Best upon the Best Practices provided by Citrix: https://support.citrix.com/article/CTX121149

  Copyright (c) cognition IT. All rights reserved.
#>


#region NITRO settings
    # NITRO Constants
    $ContentType = "application/json"

    $SubNetIP = "192.168.0"
    $NSIP = $SubNetIP + ".2"

    $NSUserName = "nsroot"
    $NSUserPW = "nsroot"

    # Build my own credentials variable, based on password string
    #$PW = ConvertTo-SecureString "nsroot" -AsPlainText -Force
    #$MyCreds = New-Object System.Management.Automation.PSCredential ("nsroot", $PW)
    $FileRoot = "C:\GitHub\PS-NITRO\Scripts_InvokeRestMethod"
    $strDate = Get-Date -Format yyyyMMddHHmmss

    $HAEnabled = $false
#endregion NITRO settings

Write-Host "--------------------------------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Recommended Settings and Best Practices                           | " -ForegroundColor Yellow
Write-Host "| for Generic Implementation of a NetScaler Appliance (with NITRO): | " -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------------- " -ForegroundColor Yellow

# ----------------------------------------
# | Method #1: Using the SessionVariable |
# ----------------------------------------
#region Start NetScaler NITRO Session
    #Connect to the NetScaler VPX
    $Login = @{"login" = @{"username"=$NSUserName;"password"=$NSUserPW;"timeout"=”900”}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/login" -Body $Login -Method POST -SessionVariable NetScalerSession -ContentType $ContentType -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion Start NetScaler NITRO Session

Write-Host
Write-Host "Starting Modes (best practices) configuration: " -ForegroundColor Green

#region !! Adding a presentation demo break !!
# ********************************************
    Read-Host 'Press Enter to continue…' | Out-Null
    Write-Host
#endregion

# ------------------------
# | Modes Best Practices |
# ------------------------

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

    <#
        Select the Fast Ramp option.                     Note: With Fast-Ramp enabled the NetScaler starts with the congestion window of the freshest server connection. For more information refer to Citrix Blog.
        Select the Use Source IP option.                 Note: Select this mode only if an application requires the source IP address.
        Select the Use Subnet IP option.                 Note: Always select this option unless specific requirements of the network set up do not require it.
        Select the Layer 3 Mode (IP Forwarding) option.  Note: If there are security issues and you want to use the appliance as a firewall, then clear this option.
        Select the Path MTU Discovery option.            This mode helps avoid fragmentation of packets.
    #>
    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # enable ns mode FR L3 Edge USNIP PMTUD
    $payload = @{
    "nsmode"= @{
        "mode"=@(
                    "FR",           #Note: With Fast-Ramp enabled the NetScaler starts with the congestion window of the freshest server connection.
                    "USIP",         #Note: Always select this option unless specific requirements of the network set up do not require it.
                    "USNIP",        #Note: Always select this option unless specific requirements of the network set up do not require it.
                    "L3",           #Note: If there are security issues and you want to use the appliance as a firewall, then clear this option.
                    "PMTUD"         #Note: This mode helps avoid fragmentation of packets.
                )
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    try{
        $Response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue
    } catch {
        # Dig into the exception to get the Response details.
        # Note that value__ is not a typo.
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    }
#endregion Enable NetScaler Modes

#region Disable NetScaler Modes
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
    $strURI = "http://$NSIP/nitro/v1/config/nsmode?action=disable"

    <#
        Clear the Layer 2 Mode option.                 Note: Select this mode if servers are connected directly to the appliance or if the appliance is used as a transparent bridge.
        Clear the Client Keep-Alive option.            Note: Applications can stop working due to optimization. Select this option only when there are performance issues.
        Clear the TCP Buffering option.                Note: If the network does not support Window Scaling and there are performance issues, select this option.
        Clear the MAC Based Forwarding option.         Note: If you are using one-arm configuration, then select this option.
        Clear the Static Route Advertisement option.   Note: If you are using the dynamic routing feature, select this option.
        Clear the Direct Route Advertisement option.   
        Clear the Intranet Route Advertisement option.
        Clear the Ipv6 Static Route Advertisement option.
        Clear the Ipv6 Direct Route Advertisement option.
        Clear the Bridge BPDUs option
    #>

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # disable ns feature CH
    $payload = @{
    "nsmode"= @{
        "mode"=@(
                       "L2",       #Note: Select this mode if servers are connected directly to the appliance or if the appliance is used as a transparent bridge.
                       "CKA",      #Note: Applications can stop working due to optimization. Select this option only when there are performance issues.
                       "TCPB",     #Note: If the network does not support Window Scaling and there are performance issues, select this option.
                       "MBF",      #Note: If you are using one-arm configuration, then select this option.
                       "SRADV",    #Note: If you are using the dynamic routing feature, select this option.
                       "DRADV",
                       "IRADV",
                       "SRADV6",
                       "DRADV6",
                       "BRIDGEBPDUS"
                    )
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $Response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue
#endregion Disable NetScaler Modes

Write-Host
Write-Host "Starting Features (best practices) configuration: " -ForegroundColor Green

#region !! Adding a presentation demo break !!
# ********************************************
    Read-Host 'Press Enter to continue…' | Out-Null
    Write-Host
#endregion

# ---------------------------
# | Features Best Practices |
# ---------------------------

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
    <#
        Note: Enabling features impacts the performance of the NetScaler appliance. Enable only the features that you want to use.
    #>

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
#    $Response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue
#endregion Enable NetScaler Basic & Advanced Features


Write-Host
Write-Host "Starting Global System Settings (best practices) configuration: " -ForegroundColor Green

#region !! Adding a presentation demo break !!
# ********************************************
    Read-Host 'Press Enter to continue…' | Out-Null
    Write-Host
#endregion

# -----------------------------------------
# | Global System Settings Best Practices |
# -----------------------------------------

#region Global System Settings - TCP Parameters
<#
update

URL:http://<netscaler-ip-address>/nitro/v1/config/nstcpparam
HTTP Method:PUT
Request Headers:
Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json
Request Payload:
{"nstcpparam":{
      "ws":<String_value>,
      "wsval":<Double_value>,
      "sack":<String_value>,
      "learnvsvrmss":<String_value>,
      "maxburst":<Double_value>,
      "initialcwnd":<Double_value>,
      "recvbuffsize":<Double_value>,
      "delayedack":<Double_value>,
      "downstaterst":<String_value>,
      "nagle":<String_value>,
      "limitedpersist":<String_value>,
      "oooqsize":<Double_value>,
      "ackonpush":<String_value>,
      "maxpktpermss":<Double_value>,
      "pktperretx":<Integer_value>,
      "minrto":<Integer_value>,
      "slowstartincr":<Integer_value>,
      "maxdynserverprobes":<Double_value>,
      "synholdfastgiveup":<Double_value>,
      "maxsynholdperprobe":<Double_value>,
      "maxsynhold":<Double_value>,
      "msslearninterval":<Double_value>,
      "msslearndelay":<Double_value>,
      "maxtimewaitconn":<Double_value>,
      "kaprobeupdatelastactivity":<String_value>,
      "maxsynackretx":<Double_value>,
      "synattackdetection":<String_value>,
      "connflushifnomem":<String_value>,
      "connflushthres":<Double_value>,
      "mptcpconcloseonpassivesf":<String_value>,
      "mptcpchecksum":<String_value>,
      "mptcpsftimeout":<Double_value>,
      "mptcpsfreplacetimeout":<Double_value>,
      "mptcpmaxsf":<Double_value>,
      "mptcpmaxpendingsf":<Double_value>,
      "mptcppendingjointhreshold":<Double_value>,
      "mptcprtostoswitchsf":<Double_value>,
      "mptcpusebackupondss":<String_value>,
      "tcpmaxretries":<Double_value>,
      "mptcpimmediatesfcloseonfin":<String_value>,
      "mptcpclosemptcpsessiononlastsfclose":<String_value>,
      "tcpfastopencookietimeout":<Double_value>
}}

Response:
    HTTP Status Code on Success: 200 OK
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/nstcpparam"
    <#
        Select the Window Scaling option.
        Note: Clear the Window Scaling option only if it is not supported by the network.
        In NetScaler 10.5, 11.0 and 11.1 builds the "Window Scaling" option is under System > Settings > Change TCP Parameters.
            #Personal Note: Check out https://support.citrix.com/article/CTX113656 for info on the Window Scaling Factor

        Select the Selective Acknowledgment option.
        Note: Clear this option only if the Window Scaling option is clear.
        In NetScaler 10.5, 11.0 and 11.1 builds the "Selective Acknowledgment" option is under System > Settings > Change TCP Parameters.

        Select the Use Nagle’s algorithm option.
        Note: Select this option to use ICA or for heavy flow of small packets.
        In NetScaler 10.5, 11.0 and 11.1 builds the "Nagle’s algorithm" option is under System > Settings > Change TCP Parameters.
    #>

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # 
    $payload = @{
    "nstcpparam"= @{
        "ws"="ENABLED";      #Note: Clear the Window Scaling option only if it is not supported by the network. In NetScaler 10.5, 11.0 and 11.1 builds the "Window Scaling" option is under System > Settings > Change TCP Parameters.
        "wsval"="4";
        "sack"="ENABLED";    #Note: Clear this option only if the Window Scaling option is clear.
        "nagle"="ENABLED";   #Note: Select this option to use ICA or for heavy flow of small packets.
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $Response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue
#endregion

#region Global System Settings - Network Settings - RNAT Parameter
<#
    update

    URL:http://<netscaler-ip-address>/nitro/v1/config/rnatparam

    HTTP Method:PUT

    Request Headers:

    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json

    Request Payload:

    {"rnatparam":{
          "tcpproxy":<String_value>,
          "srcippersistency":<String_value>
    }}

    Response:

    HTTP Status Code on Success: 200 OK
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error

#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/rnatparam"

    <#
        Select the Enable RNAT TCP Proxy option.  
        set rnatparam -tcpproxy ENABLED

        Enable TCP proxy, which enables the NetScaler appliance to optimize the RNAT TCP traffic by using Layer 4 features.
        Default value: ENABLED
        Possible values = ENABLED, DISABLED  
    #>
    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # 
    $payload = @{
    "rnatparam"= @{
        "tcpproxy"="ENABLED"      #Note: Enable TCP proxy, which enables the NetScaler appliance to optimize the RNAT TCP traffic by using Layer 4 features.
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $Response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue
#endregion


Write-Host
Write-Host "Starting HTTP Parameters (best practices) configuration: " -ForegroundColor Green

#region !! Adding a presentation demo break !!
# ********************************************
    Read-Host 'Press Enter to continue…' | Out-Null
    Write-Host
#endregion

# -------------------------------------------
# | HTTP Parameters Settings Best Practices |
# -------------------------------------------

#region HTTP Parameters Settings - Cookie version
<#
update

URL:http://<netscaler-ip-address>/nitro/v1/config/nsparam

HTTP Method:PUT

Request Headers:

Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
Content-Type:application/json

Request Payload:

{"nsparam":{
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
      "exclusivequotaspillover":<Double_value>,
      "useproxyport":<String_value>,
      "internaluserlogin":<String_value>,
      "aftpallowrandomsourceport":<String_value>,
      "icaports":<Integer[]_value>,
      "tcpcip":<String_value>,
      "servicepathingressvlan":<Double_value>
}}

Response:

HTTP Status Code on Success: 200 OK
HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/nsparam"
    <#
        Select the Version 1 option.
        Note: Select the Version 0 option only if the environment has earlier releases of web browser that do not support Cookie Version 1.
    #>

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # 
    $payload = @{
    "nsparam"= @{
        "cookieversion"="1"       #Note: Select the Version 0 option only if the environment has earlier releases of web browser that do not support Cookie Version 1.
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $Response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue
#endregion

#region HTTP Parameters Settings - Drop Invalid HTTP requests
<#
update

URL:http://<netscaler-ip-address>/nitro/v1/config/nshttpparam

HTTP Method:PUT

Request Headers:

Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
Content-Type:application/json

Request Payload:

{"nshttpparam":{
      "dropinvalreqs":<String_value>,
      "markhttp09inval":<String_value>,
      "markconnreqinval":<String_value>,
      "insnssrvrhdr":<String_value>,
      "nssrvrhdr":<String_value>,
      "logerrresp":<String_value>,
      "conmultiplex":<String_value>,
      "maxreusepool":<Double_value>
}}

Response:

HTTP Status Code on Success: 200 OK
HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error

#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/nshttpparam"
    <#
        Select the Drop invalid HTTP requests option.
        Ensure that you always select this option. It helps in detecting the invalid HTTP headers.
    #>

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # 
    $payload = @{
    "nshttpparam"= @{
        "dropinvalreqs"="ON"       #Note: Ensure that you always select this option. It helps in detecting the invalid HTTP headers.
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $Response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue
#endregion


Write-Host
Write-Host "Starting SNMP Alarms (best practices) configuration: " -ForegroundColor Green

#region !! Adding a presentation demo break !!
# ********************************************
    Read-Host 'Press Enter to continue…' | Out-Null
    Write-Host
#endregion

# ---------------------------------------
# | SNMP Alarms Settings Best Practices |
# ---------------------------------------

#region SNMP Alarms Settings (bulk)
<#
update

URL:http://<netscaler-ip-address>/nitro/v1/config/snmpalarm

HTTP Method:PUT

Request Headers:

Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
Content-Type:application/json

Request Payload:

{"snmpalarm":{
      "trapname":<String_value>,
      "thresholdvalue":<Double_value>,
      "normalvalue":<Double_value>,
      "time":<Double_value>,
      "state":<String_value>,
      "severity":<String_value>,
      "logging":<String_value>
}}

Response:

HTTP Status Code on Success: 200 OK
HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/snmpalarm"
    <#
        Select the CPU-USAGE alarm in the SNMP Alarms page.
        Configure the following options in the Configure SNMP Alarm dialog box:
            Type 95 in the Alarm Threshold field.
            Type 35 in the Normal Threshold field.
            Select Informational from the Severity list.
            Select the Enable option.
            Click OK.

        Select the MEMORY alarm and click Open.
        Configure the following options in the Configure SNMP Alarm dialog box:
            Type 95 in the Alarm Threshold field.
            Note: If this threshold is reached, then force failover the appliance. If it happens again, then contact Citrix Technical Support.
            Type 35 in the Normal Threshold field.
            Select Critical from the Severity list.
            Select Enabled from the Logging list.
            Select the Enable option.
    #>

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # 
    $payload = @{
    "snmpalarm"= @(
            @{"trapname"="CPU-USAGE";"thresholdvalue"=95;"normalvalue"=35;"state"="ENABLED";"severity"="Informational"},
            @{"trapname"="MEMORY";"thresholdvalue"=95;"normalvalue"=35;"state"="ENABLED";"severity"="Critical";"logging"="ENABLED"}        #Note: If this threshold is reached, then force failover the appliance. If it happens again, then contact Citrix Technical Support.
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $Response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue
#endregion


Write-Host
Write-Host "Starting Network Interfaces (best practices) configuration: " -ForegroundColor Green

#region !! Adding a presentation demo break !!
# ********************************************
    Read-Host 'Press Enter to continue…' | Out-Null
    Write-Host
#endregion

# ----------------------------------------------
# | Network Interfaces Settings Best Practices |
# ----------------------------------------------

#region Network Interface Settings (scripted) - Turn off HA Monitoring (only when HA is enabled)

#Check if HA is enabled on the NetScaler (When only one node is available 
    <#
    get (all)
        URL:http://<netscaler-ip-address>/nitro/v1/stat/hanode
        Query-parameters:
        args
            http://<netscaler-ip-address>/nitro/v1/stat/hanode?args=detail:<Boolean_value>,fullvalues:<Boolean_value>,ntimes:<Double_value>,logfile:<String_value>,clearstats:<String_value>
        Use this query-parameter to get hanode resources based on additional properties.
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
            { "hanode": [ {
                  "haerrsyncfailure":<Double_value>,
                  "transtime":<String_value>,
                  "hacurstatus":<String_value>,
                  "hacurmasterstate":<String_value>,
                  "hatotpkttx":<Double_value>,
                  "hapktrxrate":<Double_value>,
                  "haerrproptimeout":<Double_value>,
                  "hapkttxrate":<Double_value>,
                  "hacurstate":<String_value>,
                  "hatotpktrx":<Double_value>
            }]}
    #>
    # Specifying the correct URL 
    # NOTE: using statistical information to determine the HA State of the NetScaler!!
    $strURI = "http://$NSIP/nitro/v1/stat/hanode"

    # Method #1: Making the REST API call to the NetScaler
    $Response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue

    #hacurstatus<String>: Whether a NetScaler appliance is configured for high availability. Possible values are YES and NO. If the value is NO, the high availability statistics below are invalid.
    If ($Response.hanode.hacurstatus -eq "YES")
    {
        $HAEnabled = $true
    }

If ($HAEnabled)
{
    <#
        update

        URL:http://<netscaler-ip-address>/nitro/v1/config/Interface

        HTTP Method:PUT

        Request Headers:

        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json

        Request Payload:

        {"Interface":{
              "id":<String_value>,
              "speed":<String_value>,
              "duplex":<String_value>,
              "flowctl":<String_value>,
              "autoneg":<String_value>,
              "hamonitor":<String_value>,
              "haheartbeat":<String_value>,
              "mtu":<Double_value>,
              "tagall":<String_value>,
              "trunk":<String_value>,
              "trunkmode":<String_value>,
              "trunkallowedvlan":<String[]_value>,
              "lacpmode":<String_value>,
              "lacpkey":<Double_value>,
              "lagtype":<String_value>,
              "lacppriority":<Double_value>,
              "lacptimeout":<String_value>,
              "ifalias":<String_value>,
              "throughput":<Double_value>,
              "linkredundancy":<String_value>,
              "bandwidthhigh":<Double_value>,
              "bandwidthnormal":<Double_value>,
              "lldpmode":<String_value>,
              "lrsetpriority":<Double_value>
        }}

        Response:

        HTTP Status Code on Success: 200 OK
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
        # Specifying the correct URL 
        $strURI = "http://$NSIP/nitro/v1/config/Interface?filter=linkstate:0"
        <#
            Disable High Availability Monitoring on all disabled interfaces and on the enabled interface that does not require High Availability Monitoring. To disable High Availability Monitoring on an interface, complete the following procedure:
                Select the interface.
                Select the OFF option for HA Monitoring.
        #>

        # Method #1: Making the REST API call to the NetScaler
        $Response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue
        # linkstate (0 or 1) shows whether the link on the interface is UP or not.
        #$Response.Interface | Select-Object id, devicename, unit, description, vlan, hamonitor, haheartbeat, state, linkstate

        If ($Response.Interface.Count -gt 0)
        {
            <#
                update
                URL:http://<netscaler-ip-address>/nitro/v1/config/Interface
                HTTP Method:PUT
                Request Headers:
                    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
                    Content-Type:application/json
                Request Payload:
                {"Interface":{
                      "id":<String_value>,
                      "speed":<String_value>,
                      "duplex":<String_value>,
                      "flowctl":<String_value>,
                      "autoneg":<String_value>,
                      "hamonitor":<String_value>,
                      "haheartbeat":<String_value>,
                      "mtu":<Double_value>,
                      "tagall":<String_value>,
                      "trunk":<String_value>,
                      "trunkmode":<String_value>,
                      "trunkallowedvlan":<String[]_value>,
                      "lacpmode":<String_value>,
                      "lacpkey":<Double_value>,
                      "lagtype":<String_value>,
                      "lacppriority":<Double_value>,
                      "lacptimeout":<String_value>,
                      "ifalias":<String_value>,
                      "throughput":<Double_value>,
                      "linkredundancy":<String_value>,
                      "bandwidthhigh":<Double_value>,
                      "bandwidthnormal":<Double_value>,
                      "lldpmode":<String_value>,
                      "lrsetpriority":<Double_value>
                }}

                Response:

                HTTP Status Code on Success: 200 OK
                HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
            #>
            # Specifying the correct URL 
            $strURI = "http://$NSIP/nitro/v1/config/Interface"

            #create the Array to hold the list of interface hash tables
            $InterfaceArray = $null
            $InterfaceArray = @()

            Foreach ($Interface in $Response.Interface)
            {
                $InterfaceHash = $null
                $InterfaceHash = @{}
                $InterfaceHash.Add("id",$Interface.id)
                $InterfaceHash.Add("hamonitor","OFF")
                $InterfaceArray += $InterfaceHash
            }

            $payloadHash = @{}
            $payloadHash."Interface"=$InterfaceArray
            $payload = ConvertTo-Json $payloadHash
            # Logging NetScaler Instance payload formatting
            Write-Host "payload: " -ForegroundColor Yellow
            Write-Host ($payload) -ForegroundColor Green

            # Method #1: Making the REST API call to the NetScaler
            $Response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue
        }
}
Else
{
    Write-Warning "NO High Availability configured, so HA Monitoring is not disabled for the DISABLED network interfaces" 
}

#endregion

#region Network Interface Settings (scripted) - Disable Interfaces with DOWN (0) linkstate
<#
get (all)
URL:http://<netscaler-ip-address>/nitro/v1/config/Interface

Query-parameters:
    attrs
        http://<netscaler-ip-address>/nitro/v1/config/Interface?attrs=property-name1,property-name2
    Use this query parameter to specify the resource details that you want to retrieve.

    filter
        http://<netscaler-ip-address>/nitro/v1/config/Interface?filter=property-name1:property-val1,property-name2:property-val2
    Use this query-parameter to get the filtered set of Interface resources configured on NetScaler.Filtering can be done on any of the properties of the resource.

    view
        http://<netscaler-ip-address>/nitro/v1/config/Interface?view=summary
    Use this query-parameter to get the summary output of Interface resources configured on NetScaler.
    Note: By default, the retrieved results are displayed in detail view (?view=detail).

    pagination
        http://<netscaler-ip-address>/nitro/v1/config/Interface?pagesize=#no&pageno=#no
    Use this query-parameter to get the Interface resources in chunks.

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
        { "Interface": [ {
              "id":<String_value>,
              "devicename":<String_value>,
              "unit":<Double_value>,
              "description":<String_value>,
              "flags":<Double_value>,
              "mtu":<Double_value>,
              "actualmtu":<Double_value>,
              "vlan":<Double_value>,
              "mac":<String_value>,
              "uptime":<Double_value>,
              "downtime":<Double_value>,
              "reqmedia":<String_value>,
              "reqspeed":<String_value>,
              "reqduplex":<String_value>,
              "reqflowcontrol":<String_value>,
              "actmedia":<String_value>,
              "actspeed":<String_value>,
              "actduplex":<String_value>,
              "actflowctl":<String_value>,
              "mode":<String_value>,
              "hamonitor":<String_value>,
              "haheartbeat":<String_value>,
              "state":<String_value>,
              "autoneg":<String_value>,
              "autonegresult":<Double_value>,
              "tagged":<Double_value>,
              "tagall":<String_value>,
              "trunk":<String_value>,
              "trunkmode":<String_value>,
              "trunkallowedvlan":<String[]_value>,
              "taggedany":<Double_value>,
              "taggedautolearn":<Double_value>,
              "hangdetect":<Double_value>,
              "hangreset":<Double_value>,
              "linkstate":<Double_value>,
              "intfstate":<Double_value>,
              "rxpackets":<Double_value>,
              "rxbytes":<Double_value>,
              "rxerrors":<Double_value>,
              "rxdrops":<Double_value>,
              "txpackets":<Double_value>,
              "txbytes":<Double_value>,
              "txerrors":<Double_value>,
              "txdrops":<Double_value>,
              "indisc":<Double_value>,
              "outdisc":<Double_value>,
              "fctls":<Double_value>,
              "hangs":<Double_value>,
              "stsstalls":<Double_value>,
              "txstalls":<Double_value>,
              "rxstalls":<Double_value>,
              "bdgmacmoved":<Double_value>,
              "bdgmuted":<Double_value>,
              "vmac":<String_value>,
              "vmac6":<String_value>,
              "lacpmode":<String_value>,
              "lacpkey":<Double_value>,
              "lacppriority":<Double_value>,
              "lacptimeout":<String_value>,
              "lagtype":<String_value>,
              "ifalias":<String_value>,
              "reqthroughput":<Double_value>,
              "linkredundancy":<String_value>,
              "actthroughput":<Double_value>,
              "bandwidthhigh":<Double_value>,
              "bandwidthnormal":<Double_value>,
              "backplane":<String_value>,
              "ifnum":<String[]_value>,
              "cleartime":<Double_value>,
              "slavestate":<Double_value>,
              "slavemedia":<Double_value>,
              "slavespeed":<Double_value>,
              "slaveduplex":<Double_value>,
              "slaveflowctl":<Double_value>,
              "slavetime":<Double_value>,
              "intftype":<String_value>,
              "lacpactormode":<String_value>,
              "lacpactortimeout":<String_value>,
              "lacpactorpriority":<Double_value>,
              "lacpactorportno":<Double_value>,
              "lacppartnerstate":<String_value>,
              "lacppartnertimeout":<String_value>,
              "lacppartneraggregation":<String_value>,
              "lacppartnerinsync":<String_value>,
              "lacppartnercollecting":<String_value>,
              "lacppartnerdistributing":<String_value>,
              "lacppartnerdefaulted":<String_value>,
              "lacppartnerexpired":<String_value>,
              "lacppartnerpriority":<Double_value>,
              "lacppartnersystemmac":<String_value>,
              "lacppartnersystempriority":<Double_value>,
              "lacppartnerportno":<Double_value>,
              "lacppartnerkey":<Double_value>,
              "lacpactoraggregation":<String_value>,
              "lacpactorinsync":<String_value>,
              "lacpactorcollecting":<String_value>,
              "lacpactordistributing":<String_value>,
              "lacpportmuxstate":<String_value>,
              "lacpportrxstat":<String_value>,
              "lacpportselectstate":<String_value>,
              "lldpmode":<String_value>,
              "lrsetpriority":<Double_value>,
              "lractiveintf":<Boolean_value>
        }]}
#>
    # Specifying the correct URL 
#    $strURI = "http://$NSIP/nitro/v1/config/Interface"
    $strURI = "http://$NSIP/nitro/v1/config/Interface?filter=linkstate:0"
    <#
        Select the interface not in use and click Disable.
        Repeat this step for each interface that is not in use.
    #>

    # Method #1: Making the REST API call to the NetScaler
    $Response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue
    # linkstate (0 or 1) shows whether the link on the interface is UP or not.
    #$Response.Interface | Select-Object id, devicename, unit, description, vlan, hamonitor, haheartbeat, state, linkstate

    If ($Response.Interface.Count -gt 0)
    {
        <#
            disable

            URL:http://<netscaler-ip-address>/nitro/v1/config/Interface?action=disable
            HTTP Method:POST
            Request Headers:
                Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
                Content-Type:application/json
            Request Payload:
                {"Interface":{
                      "id":<String_value>
                }}
            Response:
                HTTP Status Code on Success: 200 OK
                HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
        #>
        # Specifying the correct URL 
        $strURI = "http://$NSIP/nitro/v1/config/Interface?action=disable"

        #create the Array to hold the list of interface hash tables
        $InterfaceArray = $null
        $InterfaceArray = @()

        Foreach ($Interface in $Response.Interface)
        {
            $InterfaceHash = $null
            $InterfaceHash = @{}
            $InterfaceHash.Add("id",$Interface.id)
            $InterfaceArray += $InterfaceHash
            Write-Host ("Interface " + $Interface.id.ToString() + " linkstate is ") -ForegroundColor Green -NoNewline
            Write-Host ($Interface.linkstate.ToString()) -ForegroundColor Yellow -NoNewline
            Write-Host (" and state is ") -ForegroundColor Green -NoNewline
            Write-Host ($Interface.state.ToString()) -ForegroundColor Yellow
        }

        $payloadHash = @{}
        $payloadHash."Interface"=$InterfaceArray
        $payload = ConvertTo-Json $payloadHash
        # Logging NetScaler Instance payload formatting
        Write-Host "payload: " -ForegroundColor Yellow
        Write-Host ($payload) -ForegroundColor Green

        # Method #1: Making the REST API call to the NetScaler
        $Response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue
    }
#endregion







#region End NetScaler NITRO Session
    #Disconnect from the NetScaler VPX
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session
