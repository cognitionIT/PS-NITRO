<#
.SYNOPSIS
  Configure Basic GSLB Settings on the NetScaler VPX.
.DESCRIPTION
  Configure Basic GSLB Settings on the NetScaler VPX, using the Invoke-RestMethod cmdlet for the REST API calls.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-06-05
  Purpose:        Created as part of the design document to quickly test some settings

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

Write-Host "--------------------------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Pushing the GSLB configuration to NetScaler with NITRO:     | " -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------- " -ForegroundColor Yellow

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
        "feature"=@("GSLB","CS")
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Enable NetScaler Basic & Advanced Features


# --------------------
# | Add GSLB Site IP |
# --------------------
#region Add GSLB Site IP
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/nsip"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add ns ip 192.168.59.5 255.255.255.255 -type GSLBsiteIP -vServer DISABLED -telnet DISABLED -ftp DISABLED -gui DISABLED -snmp DISABLED

    $payload = @{
    "nsip"= @{
      "ipaddress"=($SubNetIP + ".5");
      "netmask"="255.255.255.0";
      "type"="GSLBsiteIP";
      "vserver" = "DISABLED";
      "telnet"="DISABLED";
      "ftp"="DISABLED";
      "gui"="DISABLED";
      "snmp"="DISABLED"
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add GSLB Site IP

# --------------------
# | Add ADNS Service |
# --------------------
#region Add ADNS Server IP
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/server"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add server 192.168.59.3 192.168.59.3

    $payload = @{
    "server"= @{
      "name"=($SubnetIP + ".3");
      "ipaddress"=($SubnetIP + ".3");
      "comment"="created with PowerShell for ADNS service"
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
#    Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add ADNS Server IP

#region Add ADNS Service
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/service"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add service svc_ADNS 192.168.59.3 ADNS 53 -gslb NONE -maxClient 0 -maxReq 0 -cip DISABLED -usip NO -useproxyport NO -sp OFF -cltTimeout 120 -svrTimeout 120 -CKA NO -TCPB NO -CMP NO

    $payload = @{
    "service"= @{
      "name"="svc_ADNS";
      "ip"=($SubnetIP + ".3");
      "servicetype"="ADNS";
      "port"=53;
      "maxclient"=0;
      "maxreq"=0;
      "cip"="DISABLED";
      "usip"="NO";
      "useproxyport"="NO";
      "sp"="OFF";
      "clttimeout"=120;
      "svrtimeout"=120;
      "cka"="NO";
      "tcpb"="NO";
      "cmp"="NO"
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add ADNS Service


#region Create DNS Name Server records
<#
    add

    URL:http://<netscaler-ip-address>/nitro/v1/config/dnsnsrec

    HTTP Method:POST

    Request Headers:

    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json

    Request Payload:

    {"dnsnsrec":{
          "domain":<String_value>,
          "nameserver":<String_value>,
          "ttl":<Double_value>
    }}

    Response:

    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/dnsnsrec"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add dns nsRec gslb.demo.lab nsnitro.gslb.demo.lab

    $payload = @{
    "dnsnsrec"= @{
          "domain"="gslb.demo.lab";
          "nameserver"="nsnitro.gslb.demo.lab";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Create DNS Name Server records

#region Create DNS SOA record
<#
    add

    URL:http://<netscaler-ip-address>/nitro/v1/config/dnssoarec

    HTTP Method:POST

    Request Headers:

    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json

    Request Payload:

    {"dnssoarec":{
          "domain":<String_value>,
          "originserver":<String_value>,
          "contact":<String_value>,
          "serial":<Double_value>,
          "refresh":<Double_value>,
          "retry":<Double_value>,
          "expire":<Double_value>,
          "minimum":<Double_value>,
          "ttl":<Double_value>
    }}

    Response:

    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/dnssoarec"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add dns soaRec gslb.demo.lab -originServer nsnitro.gslb.demo.lab -contact admin.demo.lab

    $payload = @{
    "dnssoarec"= @{
          "domain"="gslb.demo.lab";
          "originserver"="nsnitro.gslb.demo.lab";
          "contact"="admin.demo.lab";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Create DNS SOA record

# Create DNS A Record
#region Create DNS A record
<#
    add

    URL:http://<netscaler-ip-address>/nitro/v1/config/dnsaddrec
    HTTP Method:POST
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
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). 
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/dnsaddrec"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add dns addRec nsnitro.gslb.demo.lab 192.168.0.2

    $payload = @{
    "dnsaddrec"= @{
      "hostname"="nsnitro.gslb.demo.lab";
      "ipaddress"=($SubnetIP + ".2");
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Create DNS A record


# --------------------------
# | Add GSLB Configuration |
# --------------------------
#region Add GSLB Sites (bulk)
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/gslbsite"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add gslb site Site1 192.168.0.5 -publicIP 192.168.0.5
    # add gslb site Site2 192.168.10.5 -publicIP 192.168.10.5

    $payload = @{
    "gslbsite"= @( 
        @{"sitename"="Site1";"sitetype"="LOCAL";"siteipaddress"=($SubnetIP + ".5");"publicip"=($SubnetIP + ".5")},
        @{"sitename"="Site2";"sitetype"="REMOTE";"siteipaddress"="192.168.10.5";"publicip"="192.168.10.5"}
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add GSLB local site

#region Add GSLB services (bulk)
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/gslbservice"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add gslb service gslb_svc_nsg_vpn_test_site1 192.168.0.9 SSL 443 -publicIP 192.168.0.9 -publicPort 443 -maxClient 0 -siteName Site1 -cltTimeout 180 -svrTimeout 360 -downStateFlush ENABLED
    # add gslb service gslb_svc_nsg_vpn_test_site2 192.168.10.9 SSL 443 -publicIP 192.168.10.9 -publicPort 443 -maxClient 0 -siteName Site2 -cltTimeout 180 -svrTimeout 360 -downStateFlush ENABLED

    $payload = @{
    "gslbservice"= @(
            @{
              "servicename"= "gslb_svc_nsg_vpn_test_site1";
              "ip"=($SubnetIP + ".9");
              "servicetype"="SSL";
              "port"=443;
              "publicip"=($SubnetIP + ".9");
              "publicport"=443;
              "maxclient"=0;
              "sitename"="Site1";
              "clttimeout"=180;
              "svrtimeout"=360;
              "downstateflush"="ENABLED"
            },
            @{
              "servicename"= "gslb_svc_nsg_vpn_test_site2";
              "ip"="192.168.10.9";
              "servicetype"="SSL";
              "port"=443;
              "publicip"="192.168.10.9";
              "publicport"=443;
              "maxclient"=0;
              "sitename"="Site2";
              "clttimeout"=180;
              "svrtimeout"=360;
              "downstateflush"="ENABLED"
            }
        )

    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add GSLB service

#region Add GSLB vServer (bulk)
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/gslbvserver"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add gslb vserver gslb_vsvr_SFStore SSL -backupLBMethod ROUNDROBIN -tolerance 0 -EDR ENABLED -ECS ENABLED -appflowLog DISABLED
    # set gslb vserver gslb_vsvr_SFStore -backupLBMethod ROUNDROBIN -tolerance 0 -EDR ENABLED -ECS ENABLED -appflowLog DISABLED

    $payload = @{
    "gslbvserver"= @(
            @{
              "name"="gslb_vsvr_nsg_vpn_test";
              "servicetype"="SSL";
              "iptype"="IPV4"; # default value
              "dnsrecordtype"="A"; # default value
              "lbmethod"="LEASTCONNECTION"; # default value
              "backuplbmethod"= "ROUNDROBIN";
              "tolerance"=0;
              "edr"="ENABLED";
              "ecs"="ENABLED";
              "appflowlog"="DISABLED"
            },
            @{
              "name"="gslb_vsvr_nsg_vpn_backup";
              "servicetype"="SSL";
              "iptype"="IPV4"; # default value
              "dnsrecordtype"="A"; # default value
              "lbmethod"="LEASTCONNECTION"; # default value
              "backuplbmethod"= "ROUNDROBIN";
              "tolerance"=0;
              "edr"="ENABLED";
              "ecs"="ENABLED";
              "appflowlog"="DISABLED"
            }
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add GSLB vServer

#region Update GSLB vServer
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/gslbvserver"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add gslb vserver gslb_vsvr_SFStore SSL -backupLBMethod ROUNDROBIN -tolerance 0 -EDR ENABLED -ECS ENABLED -appflowLog DISABLED
    # set gslb vserver gslb_vsvr_SFStore -backupLBMethod ROUNDROBIN -tolerance 0 -EDR ENABLED -ECS ENABLED -appflowLog DISABLED

    $payload = @{
    "gslbvserver"= @{
      "name"="gslb_vsvr_nsg_vpn_test";
      "backupvserver"="gslb_vsvr_nsg_vpn_backup";
      "comment"="updated with a backup vserver";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Uri $strURI -Method Put -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add GSLB vServer

# Note: You need to perform an update to specify a backup vserver for this gslb vserver.
#region Add GSLB vServer binding domain name
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/gslbvserver_domain_binding"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # bind gslb vserver gslb_vsvr_SFStore -domainName gateway.gslb.demo.lab -TTL 5

    $payload = @{
    "gslbvserver_domain_binding"= @{
      "name"="gslb_vsvr_nsg_vpn_test";
      "domainname"="gateway.gslb.demo.lab";
      "ttl"=5
#      "backupip":<String_value>;
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add GSLB vServer binding domain name

#region Add GSLB vServer binding service (bulk)
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/gslbvserver_gslbservice_binding"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # bind gslb vserver gslb_vsvr_SFStore -serviceName gslb_svc_SFStore_Site1

    $payload = @{
    "gslbvserver_gslbservice_binding"= @(
            @{
              "name"="gslb_vsvr_nsg_vpn_test";
              "servicename"="gslb_svc_nsg_vpn_test_site1"
        #      "weight":<Double_value>;
        #      "domainname":<String_value>
            },
            @{
              "name"="gslb_vsvr_nsg_vpn_backup";
              "servicename"="gslb_svc_nsg_vpn_test_site2"
        #      "weight":<Double_value>;
        #      "domainname":<String_value>
            }
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add GSLB vServer binding service


#TODO:


#region End NetScaler NITRO Session
    #Disconnect from the NetScaler VPX
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session



<#
CLI:

#NS11.1 Build 48.10
# Last modified Thu Aug  4 21:49:06 2016

enable ns feature CS GSLB

add ns ip 192.168.59.5 255.255.255.255 -type GSLBsiteIP -vServer DISABLED -telnet DISABLED -ftp DISABLED -gui DISABLED -snmp DISABLED

add server 192.168.59.101 192.168.59.101
add server 192.168.59.3 192.168.59.3

add service svc_ADNS 192.168.59.3 ADNS 53 -gslb NONE -maxClient 0 -maxReq 0 -cip DISABLED -usip NO -useproxyport NO -sp OFF -cltTimeout 120 -svrTimeout 120 -CKA NO -TCPB NO -CMP NO

add cs vserver cs_vsvr_test SSL 192.168.59.102 443 -cltTimeout 180

add gslb vserver gslb_vsvr_SFStore SSL -backupLBMethod ROUNDROBIN -tolerance 0 -EDR ENABLED -ECS ENABLED -appflowLog DISABLED
set gslb vserver gslb_vsvr_SFStore -backupLBMethod ROUNDROBIN -tolerance 0 -EDR ENABLED -ECS ENABLED -appflowLog DISABLED

add cs action cs_act_switch -targetLBVserver vsvr_SFStore
add cs policy cs_pol_switch -url "/server.demo.lab"

add gslb site Site1 192.168.59.5 -publicIP 192.168.59.5

bind cs vserver cs_vsvr_test -policyName cs_pol_switch -targetLBVserver vsvr_SFStore

add gslb service gslb_svc_SFStore_Site1 192.168.59.101 SSL 443 -publicIP 192.168.59.101 -publicPort 443 -maxClient 0 -siteName Site1 -cltTimeout 180 -svrTimeout 360 -downStateFlush ENABLED
bind gslb vserver gslb_vsvr_SFStore -serviceName gslb_svc_SFStore_Site1
bind gslb vserver gslb_vsvr_SFStore -domainName gateway.gslb.demo.lab -TTL 5

bind ssl vserver gslb_vsvr_SFStore -eccCurveName P_256
bind ssl vserver gslb_vsvr_SFStore -eccCurveName P_384
bind ssl vserver gslb_vsvr_SFStore -eccCurveName P_224
bind ssl vserver gslb_vsvr_SFStore -eccCurveName P_521
bind ssl vserver cs_vsvr_test -eccCurveName P_256
bind ssl vserver cs_vsvr_test -eccCurveName P_384
bind ssl vserver cs_vsvr_test -eccCurveName P_224
bind ssl vserver cs_vsvr_test -eccCurveName P_521

#>