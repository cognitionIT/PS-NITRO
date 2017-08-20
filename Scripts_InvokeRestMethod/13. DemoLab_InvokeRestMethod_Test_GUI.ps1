<#
.SYNOPSIS
  Creating a LB vServer mini management GUI.
.DESCRIPTION
  Creating a LB vServer mini management GUI, using the Invoke-RestMethod cmdlet for the REST API calls.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-08-17
  Purpose:        Created to quickly test GUI options to create a mini management interface (delegated control)

  Copyright (c) cognition IT. All rights reserved.
#>

#--------------#
# TESTING AREA #
#--------------#

#region Testing area
$ContentType = "application/json"
$NSIP = "192.168.59.2"
$NSUserName = "nsroot"
$NSUserPW = "nsroot"

# ---------------------------------------------------------
# | Login to NITRO - Method #1: Using the SessionVariable |
# ---------------------------------------------------------
    #region Start NetScaler NITRO Session
        #Connect to the NetScaler VPX
        $Login = @{"login" = @{"username"=$NSUserName;"password"=$NSUserPW;"timeout"=”900”}} | ConvertTo-Json
        $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/login" -Body $Login -Method POST -SessionVariable NetScalerSession -ContentType $ContentType -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
    #endregion Start NetScaler NITRO Session

    #region Retrieve LB vServers
        # Specifying the correct URL 
        $strURI = "http://$NSIP/nitro/v1/config/lbvserver"
        # Method #1: Making the REST API call to the NetScaler
#        $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference

# FOR TESTING PURPOSES WITHOUT A NETSCALER
        # Read JSON content from input file and convert to PS Object (Array)
        $response = Get-Content -Raw -Path "C:\Input\Config\response.json" | ConvertFrom-Json


        If ($response.errorcode -eq 0)
        {
            Write-Host "LB vServer list: " -ForegroundColor Yellow
            for ($i=0;$i -le ($response.lbvserver.Length - 1);$i++)
            {
                Write-Host ("listitem: "+ $response.lbvserver[$i].name) -ForegroundColor Green
            }
        }

    #endregion Retrieve LB vServers





    #region End NetScaler NITRO Session
        #Disconnect from the NetScaler VPX
        $LogOut = @{"logout" = @{}} | ConvertTo-Json
        $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
    #endregion End NetScaler NITRO Session

#endregion Testing Area


