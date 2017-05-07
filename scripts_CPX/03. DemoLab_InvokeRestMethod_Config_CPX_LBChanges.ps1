﻿# Add the Basic Load Balancing configuration to the NetScaler CPX

#region NITRO settings
    $ContentType = "application/json"
    $NSUserName = "nsroot"
    $NSUserPW = "nsroot"

    $PW = ConvertTo-SecureString $NSUserPW -AsPlainText -Force
    $MyCreds = New-Object System.Management.Automation.PSCredential ($NSUserName, $PW)

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

Write-Host "--------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Disabling the Blue webservice with NITRO: | " -ForegroundColor Yellow
Write-Host "--------------------------------------------- " -ForegroundColor Yellow

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

# -------------------------------------------
# | Disable the blue webservice & Get stats |
# -------------------------------------------

Write-Host "* Disabling the Blue webservice with NITRO: " -ForegroundColor Cyan

#region disable LB Service blue
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/service?action=disable"

    $payload = @{
        "service"= @{
          "name"="svc_webserver_blue"
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "URL: " -ForegroundColor Yellow -NoNewline
    Write-Host $strURI -ForegroundColor Green
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Disable LB Service blue

#region Get LB Services stats
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/stat/service/svc_webserver_blue"

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    Write-Host "response: " -ForegroundColor Green
    $response.service | Select-Object name, servicetype, state, totalrequests | Format-List
#endregion Get LB Services stats

Start-Sleep 5
#region Get LB vServer stats
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/stat/lbvserver?args=name:vsvr_webserver_81"

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    Write-Host "response: " -ForegroundColor Green
    $response.lbvserver | Select-object name, type, state, vslbhealth, actsvcs | Format-List

    Write-Host "LB vServer Status: "
#endregion Add LB Services

Write-Host "-------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Enabling the Blue webservice with NITRO: | " -ForegroundColor Yellow
Write-Host "-------------------------------------------- " -ForegroundColor Yellow


# ------------------------------------------
# | Enable the blue webservice & Get stats |
# ------------------------------------------

Write-Host "* Enabling the Blue webservice with NITRO: " -ForegroundColor Cyan

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

#region enable LB Service blue
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/service?action=enable"

    $payload = @{
        "service"= @{
          "name"="svc_webserver_blue"
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "URL: " -ForegroundColor Yellow -NoNewline
    Write-Host $strURI -ForegroundColor Green
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Disable LB Service blue

#region Get LB Services stats
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/stat/service/svc_webserver_blue"

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    Write-Host "response: " -ForegroundColor Green
#    $response.service | Select-Object name, primaryipaddress, primaryport, servicetype, state, totalrequests, cursrvrconnections, svrestablishedconn
    $response.service | Select-Object name, servicetype, state, svrestablishedconn | Format-List
#endregion Get LB Services stats

Start-Sleep 5

#region Get LB vServer stats
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/stat/lbvserver?args=name:vsvr_webserver_81"

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    Write-Host "response: " -ForegroundColor Green
#    $response.lbvserver | Select-object name, primaryipaddress, primaryport, type, state, vslbhealth, actsvcs, tothits
    $response.lbvserver | Select-object name, type, state, vslbhealth, actsvcs | Format-List
#endregion Add LB Services





