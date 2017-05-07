<#
.SYNOPSIS
  Monitoring Script for NetScaler VPX LB vServer.
.DESCRIPTION
  Monitoring Script for the NetScaler VPX LB vServer, based upon Stat REST API calls, using Invoke-RestMethod cmdlet.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-04-23

  Copyright (c) cognition IT. All rights reserved.
#>

Function ShowAlert {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$AlertTitle,
        [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$AlertMessage
    )

    # Create a windows popup window
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    # Button Options can be found here: https://msdn.microsoft.com/en-us/library/system.windows.messageboxbutton(v=vs.110).aspx
    $ButtonType = [System.Windows.MessageBoxButton]::Ok
    # Icon Options can be found here: https://msdn.microsoft.com/en-us/library/system.windows.messageboximage(v=vs.110).aspx
    $MessageIcon = [System.Windows.MessageBoxImage]::Error

    # Message Class options can be found here: https://msdn.microsoft.com/en-us/library/system.windows.messagebox(v=vs.110).aspx
    $Result = [System.Windows.MessageBox]::Show($AlertMessage,$AlertTitle,$ButtonType,$MessageIcon)
}

#region NITRO settings
    $ContentType = "application/json"
    $SubNetIP = "192.168.0"
    $NSIP = $SubNetIP + ".2"
    $PW = ConvertTo-SecureString "nsroot" -AsPlainText -Force
    $MyCreds = New-Object System.Management.Automation.PSCredential ("nsroot", $PW)

    $NSUserName = "nsroot"
    $NSUserPW = "nsroot"

    $strDate = Get-Date -Format yyyyMMddHHmmss
#endregion NITRO settings

Write-Host "------------------------------------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Monitoring NetScaler CPX Load Balancing Service & vServer with NITRO: | " -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------- " -ForegroundColor Yellow

#region Start NetScaler NITRO Session
    #Connect to the NetScaler VPX Virtual Appliance
    $Login = @{"login" = @{"username"=$NSUserName;"password"=$NSUserPW;"timeout"=”900”}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/login" -Body $Login -Method POST -SessionVariable NetScalerSession -ContentType $ContentType -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion Start NetScaler NITRO Session

    $Period = 300
    $Interval = 5
    $timeout = new-timespan -Seconds $Period

    $sw = [diagnostics.stopwatch]::StartNew()

    $Alerted = $false
    while ($sw.elapsed -lt $timeout)
    {
    #region Get LB Servicegroup member stats
        # Specifying the correct URL 
        $strURI = "http://$NSIP/nitro/v1/stat/servicegroupmember?args=servicegroupname:svcgrp_SFStore,servername:SF2,port:80"

        # Method #1: Making the REST API call to the NetScaler
        $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference

        If ($response.servicegroupmember.state -ne "UP")
        {
            Write-Host ("Blue webserver status is " + $response.servicegroupmember.state) -ForegroundColor Red
            ShowAlert -AlertTitle "Monitoring Blue webserver" -AlertMessage ("Blue webserver is " + $response.servicegroupmember.state)
        }
        Else
        {
#                Write-Host ("Blue webserver status is UP!") -ForegroundColor Green
        }
    #endregion Get LB Services stats

    #region Get LB vServer stats
        # Specifying the correct URL 
        $strURI = "http://$NSIP/nitro/v1/stat/lbvserver?args=name:vsvr_SFStore"

        # Method #1: Making the REST API call to the NetScaler
        $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference

        If (($response.lbvserver.vslbhealth -ne 100) -and ($Alerted -eq $false))
        {
            Write-Host ("LB vServer runs at " + $response.lbvserver.vslbhealth + "% capacity!") -ForegroundColor Red
        }
        Else
        {
            Write-Host ("LB vServer runs at 100% capacity") -ForegroundColor Green
        }
    #endregion Get LB vServer stats

        Start-Sleep -seconds $Interval
        # check https://msdn.microsoft.com/en-us/library/ee372287%28v=vs.110%29.aspx?f=255&MSPPError=-2147217396 for formatting options
        Write-Output ("Elapsed Time: " + $sw.Elapsed.ToString('mm\:ss'))
    }
    Write-Host "Time-out period of $Period seconds reached" -ForegroundColor Yellow

#region End NetScaler NITRO Session
    #Disconnect from the NetScaler VPX Virtual Appliance
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session
