<#
.SYNOPSIS
  Configure NetScaler VPX settings with input JSON file.
.DESCRIPTION
  Configure NetScaler VPX settings with input JSON file, using the Invoke-RestMethod cmdlet for the REST API calls.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-07-18
  Purpose:        Created to quickly test JSON file and object options

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
Write-Host "| Pushing the FAS configuration for NetScaler with NITRO:     | " -ForegroundColor Yellow
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


# NITRO NOTES:
#For PUT requests, provide warning and onerror parameters in the request payload rather than in the URI or Header.
<# For example:
     {
        "params":
        {
         "warning":"yes",
         "onerror":"continue"
        },
        "lbvserver":[
         {
          "name":<String_value>,
          ...
        }
         ....
       ]
     }
#>
#For PUT and DELETE operations, read the warning message from response payload rather than from X-NITRO-WARNING and note that status code is set to "200 Ok" instead of "209 NetScaler specific warning".
<#
   For example:
     {
       errorcode: 1067,
       message: "Feature(s) not enabled [LB]",
       severity: "WARNING"
     }
#>


# ------------------------
# | Read JSON Input file |
# ------------------------
#region Read JSON input file
    # Read JSON content from input file and convert to PS Object (Array)
    $JSONInput = Get-Content -Raw -Path "$FileRoot\Input\config.json" | ConvertFrom-Json

#source: https://blogs.msdn.microsoft.com/powershell/2009/12/04/new-object-psobject-property-hashtable/
# New-Object PSObject –Property [HashTable]

$JSONInput.PSObject

$JSONInput.PSObject.Properties.Item("params").Value

$JSONInput | Measure-Object PSObject

$JSONInput.psobject.properties.name

#endregion Read JSON input file

# ----------------------------------------
# | Actions to NetScaler |
# ----------------------------------------
#region Add certificate - key pairs
    <#
    #>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/sslcertkey"

    # add ssl certKey RootCA -cert "/nsconfig/ssl/rootCA.cer" -inform DER -expiryMonitor ENABLED -notificationPeriod 25
    $payload = @{
        "sslcertkey"= @(
            @{"certkey"="idp_root_ca"; "cert"="/nsconfig/ssl/IDPCAroot.cer"; "inform"="PEM"; "expirymonitor"="ENABLED"; "notificationperiod"=25},
            @{"certkey"="idp_demo_lab"; "cert"="/nsconfig/ssl/IDPcert.cer"; "inform"="PEM"; "expirymonitor"="ENABLED"; "notificationperiod"=25}
        )
    } | ConvertTo-Json -Depth 5

    # Method #1: Making the REST API call to the NetScaler
#    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add certificate - key pairs



#TODO:


#region End NetScaler NITRO Session
    #Disconnect from the NetScaler VPX
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session

