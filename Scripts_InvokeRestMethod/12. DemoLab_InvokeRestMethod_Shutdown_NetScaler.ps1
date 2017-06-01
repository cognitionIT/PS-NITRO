<#
.SYNOPSIS
  Shutdown the NetScaler VPX appliance.
.DESCRIPTION
  Shutdown the NetScaler VPX appliance.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-05-15
  Purpose:        Created out of curiousity

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

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

# ----------------------------------------
# | Method #1: Using the SessionVariable |
# ----------------------------------------
#region Method #1 - Using a session variable
    #region Start NetScaler NITRO Session
        #Connect to the NetScaler VPX
        $Login = @{"login" = @{"username"=$NSUserName;"password"=$NSUserPW;"timeout"=”900”}} | ConvertTo-Json
        $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/login" -Body $Login -Method POST -SessionVariable NetScalerSession -ContentType $ContentType -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
    #endregion Start NetScaler NITRO Session

# -------------------------------------
# | Enable require NetScaler Features |
# -------------------------------------
    #region Shutdown NetScaler
    <#
        Shutdown
        URL: http://<netscaler-ip-address>/nitro/v1/config/shutdown
        HTTP Method: POST
        Request Headers:
            Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
            Content-Type:application/json
        Request Payload:

        {"shutdown":{
        }}
        Response:

        HTTP Status Code on Success: 200 OK
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
        # Specifying the correct URL 
        $strURI = "http://$NSIP/nitro/v1/config/shutdown"

        # Creating the right payload formatting (mind the Depth for the nested arrays)
        # bind system global "policy name" -priority 100

        $payload = @{
        "shutdown"= @{
            }
        } | ConvertTo-Json -Depth 5

        # Logging NetScaler Instance payload formatting
        Write-Host "payload: " -ForegroundColor Yellow
        Write-Host $payload -ForegroundColor Green

        # Method #1: Making the REST API call to the NetScaler
        Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$true
    #endregion Shutdown NetScaler

    #region End NetScaler NITRO Session
        #Disconnect from the NetScaler VPX
        $LogOut = @{"logout" = @{}} | ConvertTo-Json
        $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
    #endregion End NetScaler NITRO Session
#endregion Method #1


#region Method #2: Using Request Header
# REST Header info with Credentials
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/shutdown"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # bind system global "policy name" -priority 100

    $payload = @{
    "shutdown"= @{
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    $RESTHeaders = @{
        "X-NITRO-USER"="nsroot";
        "X-NITRO-PASS"="nsroot";
        "Content-Type"="application/json";
    }

    Invoke-RestMethod -Method Post -Uri $strURI -Headers $RESTHeaders -Body $payload -Verbose
#endregion Method #2: Using Request Header




