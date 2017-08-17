<#
.SYNOPSIS
 Manage the LB Service state on the NetScaler VPX.
.DESCRIPTION
  Manage the LB Service state on the NetScaler VPX, using the Invoke-RestMethod cmdlet for the REST API calls and a custom build GUI.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-08-08
  Purpose:        Created as part of an automation service test for Generali

  Copyright (c) cognition IT. All rights reserved.
#>

# add system cmdPolicy cmd_pol_service_mgmt ALLOW "(^(disable|enable|show)\\s+(server|service|serviceGroup))|(^(disable|enable|show)\\s+(server|service|serviceGroup)\\s+.*)"

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
    #endregion Test Environment variables
    $ContentType = "application/json"
    $NSIP = ($SubnetIP + ".2")
    # Build my own credentials variable, based on password string
    $PW = ConvertTo-SecureString "nsroot" -AsPlainText -Force
    $MyCreds = New-Object System.Management.Automation.PSCredential ("nsroot", $PW)
    $FileRoot = "C:\GitHub\PS-NITRO\GUIBased"

    $NSUserName = "test"
    $NSUserPW = "test"

    $strDate = Get-Date -Format yyyyMMddHHmmss
#endregion NITRO settings

Write-Host "----------------------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Creating a GUI for NetScaler management with NITRO:     | " -ForegroundColor Yellow
Write-Host "----------------------------------------------------------- " -ForegroundColor Yellow

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

# -----------------------------------------
# |Retrieve current lb vservers and state |
# -----------------------------------------
#region Get LB vServers
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/lbvserver"

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference

    Write-Host "LB vServer Status: "-ForegroundColor Green
    $lbvservers = $response.lbvserver | Select-object name, ipv46, servicetype, curstate, effectivestate, lbmethod, health, totalservices, activeservices, vsvrbindsvcip | Format-List
#endregion Add LB Services

$response.lbvserver.name

foreach ($item in $response.lbvserver) {write-host ($item.name + " " + $item.curstate)}

<#

# -------------------------------------------
# | Disable the blue webservice & Get stats |
# -------------------------------------------
Write-Host "* Disabling the Blue webservice with NITRO: " -ForegroundColor Cyan

#region disable LB Service blue (using config)
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

Start-Sleep -Seconds 5
#region Get LB Services stats (using stat)
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/stat/service/svc_webserver_blue"

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    Write-Host "LB Services Status: " -ForegroundColor Green
    $response.service | Select-Object name, servicetype, state, totalrequests | Format-List
#endregion Get LB Services stats

Start-Sleep -Seconds 5

#region Get LB vServer stats (using stat)
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/stat/lbvserver?args=name:vsvr_webserver_81"

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference

    Write-Host "LB vServer Status: "-ForegroundColor Green
    $response.lbvserver | Select-object name, type, state, vslbhealth, actsvcs | Format-List
#endregion Add LB Services


# ------------------------------------------
# | Enable the blue webservice & Get stats |
# ------------------------------------------

Write-Host "* Enabling the Blue webservice with NITRO: " -ForegroundColor Cyan

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

#region Enable LB Service blue (using config)
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
#endregion Enable LB Service blue

#region Get LB Services stats (using stat)
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/stat/service/svc_webserver_blue"

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    Write-Host "LB Services Status: " -ForegroundColor Green
    $response.service | Select-Object name, servicetype, state, svrestablishedconn | Format-List
#endregion Get LB Services stats

Start-Sleep -Seconds 5

#region Get LB vServer stats (using stat)
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/stat/lbvserver?args=name:vsvr_webserver_81"

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    Write-Host "LB vServer Status: "-ForegroundColor Green
    $response.lbvserver | Select-object name, type, state, vslbhealth, actsvcs | Format-List
#endregion Add LB Services


#>


#region End NetScaler NITRO Session

    #Disconnect from the NetScaler VPX
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session

