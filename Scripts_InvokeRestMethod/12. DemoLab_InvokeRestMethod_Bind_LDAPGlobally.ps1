<#
.SYNOPSIS
  Bind LDAP policy globally on the NetScaler VPX.
.DESCRIPTION
  Bind LDAP policy globally on the NetScaler VPX.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-05-11
  Purpose:        Created to answer a Citrix support forum question

  Copyright (c) cognition IT. All rights reserved.
#>

#region NITRO settings
    #region Test Environment variables
        $TestEnvironment = "Elektra"

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
#region Bind LDAP policy globally
<#
    add:
        URL: http://<netscaler-ip-address/nitro/v1/config/systemglobal_authenticationldappolicy_binding
    HTTP Method: PUT
    Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
    Request Payload:
    {
    "systemglobal_authenticationldappolicy_binding":{
          "policyname":<String_value>,
          "priority":<Double_value>
    }}
    Response:
        HTTP Status Code on Success: 201 Created
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/systemglobal_authenticationldappolicy_binding"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # bind system global "policy name" -priority 100

    $payload = @{
    "systemglobal_authenticationldappolicy_binding"= @{
        "policyname"="pol_LDAP_dc001";
        "priority"=100;
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind LDAP policy globally



#region End NetScaler NITRO Session
    #Disconnect from the NetScaler VPX
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session

