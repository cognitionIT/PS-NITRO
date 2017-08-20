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

#--------------------#
# MAJOR TESTING AREA #
#--------------------#

#region Testing area

    # Specifying the input file
    $ConfigFile = "C:\Input\Config\PSNITROConfig.json"

<#
    # Creating a payload (checking formatting)
    $payload=@{
        "Settings"=@{
           "Environment"="Elektra";
	        "RootFolder"="C:\Input";
	        "ScriptFolder"="G:\GitHub\PSNITRO";
	        "SubNetIP"="192.168.59";
	        "NSLicenseFile"="C:\Input\Licenses\NSVPX-ESX_PLT_201709.lic"
        };
        "server"=@(
                @{"name"="lb_svr_one";"ip-address"="192.168.0.101"},
                @{"name"="lb_svr_two";"ip-address"="192.168.0.102"}
            )
    } | ConvertTo-Json
    $payload
#>

    # -----------------------
    # | Read the JSON Config file |
    # ------------------------
    #region Read JSON input file
        # Read JSON content from input file and convert to PS Object (Array)
        $JSONConfigInput = Get-Content -Raw -Path $ConfigFile | ConvertFrom-Json
    #endregion Read JSON input file

    #source: https://blogs.msdn.microsoft.com/powershell/2009/12/04/new-object-psobject-property-hashtable/
    # New-Object PSObject –Property [HashTable]

    #region Retrieve the Settings section from the JSON object
    $objSettings = $JSONConfigInput.PSObject.Properties.Item("Settings").Value

    #a PSObject is an array, so you should use Count to check if it is $null or not
        If ($objSettings.Count -eq 0)
        {
            Write-Host "Warning: Empty PSObject" -ForegroundColor Yellow
        }
        $objSettings.environment.Count

        #region NITRO settings
            $ContentType = "application/json"
            $SubNetIP = $objSettings.SubNetIP
            $NSIP = $SubNetIP + ".2"
            # Build my own credentials variable, based on password string
            $FileRoot = $objSettings.ScriptFolder

            If ($objSettings.NSUsername -eq $null)
            {
                $NSUserName = Read-Host "Enter the NetScaler username to use: "
            }
            Else
            {
                $NSUserName = $objSettings.NSUsername
            }
            If ($objSettings.NSPassword -eq $null)
            {
                $NSPassword = Read-Host "Enter the NetScaler password to use: " -AsSecureString
                # Create my own Credential object to decrypt the password secure string back to a unencoded string
                $MyCreds = New-Object System.Management.Automation.PSCredential ($NSUserName, $NSPassword)
                # Create a Windows PowerShell Credentials Request popup to get user credentials 
                #$MyCreds = Get-Credential
                # Show the entered Username
                #Write-Host ("Username: " + $MyCreds.UserName) -ForegroundColor Yellow
                # Show the enetered password
                #Write-Host ("Password: " + $MyCreds.GetNetworkCredential().Password) -ForegroundColor Yellow
                $NSUserPW = $MyCreds.GetNetworkCredential().Password
            }
            Else
            {
                $NSUserPW = $objSettings.NSPassword
            }
            $strDate = Get-Date -Format yyyyMMddHHmmss
        #endregion NITRO settings

    #endregion Retrieve Settings


# ---------------------------------------------------------
# | Login to NITRO - Method #1: Using the SessionVariable |
# ---------------------------------------------------------
    #region Start NetScaler NITRO Session
        #Connect to the NetScaler VPX
        $Login = @{"login" = @{"username"=$NSUserName;"password"=$NSUserPW;"timeout"=”900”}} | ConvertTo-Json
        $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/login" -Body $Login -Method POST -SessionVariable NetScalerSession -ContentType $ContentType -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
    #endregion Start NetScaler NITRO Session



    #region Retrieve the nsservers section from the JSON object
        $servers = $JSONConfigInput.PSObject.Properties.Item("nsservers").Value
        If ($servers[0] -eq $null)
        {
            Write-Host "No servers found in the configuration file" -ForegroundColor DarkYellow
        }
        Else
        {
            # Retrieve the payload from the JSON input file
            $payload = ConvertTo-Json -InputObject $servers -Depth 100
            Write-Host "payload: " -ForegroundColor Yellow
            Write-Host $payload -ForegroundColor Green
            # Specifying the correct URL 
            $strURI = "http://$NSIP/nitro/v1/config/server"
            # Method #1: Making the REST API call to the NetScaler
            $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
        }
    #endregion Retrieve nsserver




    #region End NetScaler NITRO Session
        #Disconnect from the NetScaler VPX
        $LogOut = @{"logout" = @{}} | ConvertTo-Json
        $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
    #endregion End NetScaler NITRO Session

#endregion Testing Area









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


