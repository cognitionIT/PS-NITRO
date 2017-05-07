# Change server settings to the NetScaler CPX

#region NITRO settings
    $ContentType = "application/json"
    $SubNetIP = "192.168.0"
    $NSIP = $SubNetIP + ".2"
    $PW = ConvertTo-SecureString "nsroot" -AsPlainText -Force
    $MyCreds = New-Object System.Management.Automation.PSCredential ("nsroot", $PW)
    $FileRoot = "H:\PSModules\NITRO\Scripts"

    $NSUserName = "nsroot"
    $NSUserPW = "nsroot"

    $strDate = Get-Date -Format yyyyMMddHHmmss
#endregion NITRO settings

Write-Host "-------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Disabling the Blue webserver with NITRO: | " -ForegroundColor Yellow
Write-Host "-------------------------------------------- " -ForegroundColor Yellow

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

# ------------------------------------------
# | Disable the blue webserver & Get stats |
# ------------------------------------------

Write-Host "* Disabling the Blue webserver with NITRO: " -ForegroundColor Cyan

#region disable LB webserver blue
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/servicegroup?action=disable"

    $payload = @{
        "servicegroup"= @{
          "servicegroupname"="svcgrp_SFStore";
          "servername"="SF2";
          "port"=80;
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "URL: " -ForegroundColor Yellow -NoNewline
    Write-Host $strURI -ForegroundColor Green
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Disable LB webserver blue

#region Get LB ServiceGroup stats
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/stat/servicegroup/svcgrp_SFStore"

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    Write-Host "response: " -ForegroundColor Green
    $response.servicegroup | Select-Object servicegroupname, servicetype, state | Format-List
#endregion Get LB ServiceGroup stats

Start-Sleep 5
#region Get LB vServer stats
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/stat/lbvserver?args=name:vsvr_SFStore"

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    Write-Host "response: " -ForegroundColor Green
    $response.lbvserver | Select-object name, type, state, vslbhealth, actsvcs | Format-List

    Write-Host "LB vServer Status: "
#endregion Add LB Services

Write-Host "------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Enabling the Blue webserver with NITRO: | " -ForegroundColor Yellow
Write-Host "------------------------------------------- " -ForegroundColor Yellow


# -----------------------------------------
# | Enable the blue webserver & Get stats |
# -----------------------------------------

Write-Host "* Enabling the Blue webserver with NITRO: " -ForegroundColor Cyan

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

#region enable LB Service blue
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/servicegroup?action=enable"

    $payload = @{
        "servicegroup"= @{
          "servicegroupname"="svcgrp_SFStore";
          "servername"="SF2";
          "port"=80;
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

#region Get LB ServiceGroup stats
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/stat/servicegroup/svcgrp_SFStore"

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    Write-Host "response: " -ForegroundColor Green
    $response.servicegroup | Select-Object servicegroupname, servicetype, state | Format-List
#endregion Get LB ServiceGroup stats

Start-Sleep 5

#region Get LB vServer stats
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/stat/lbvserver?args=name:vsvr_SFStore"

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    Write-Host "response: " -ForegroundColor Green
#    $response.lbvserver | Select-object name, primaryipaddress, primaryport, type, state, vslbhealth, actsvcs, tothits
    $response.lbvserver | Select-object name, type, state, vslbhealth, actsvcs | Format-List
#endregion Add LB vServer


#region End NetScaler NITRO Session
    #Disconnect from the NetScaler VPX Virtual Appliance
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session



