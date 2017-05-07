
Function ShowAlert {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$AlertTitle,
        [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$AlertMessage
    )

    # Test popup
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

Write-Host "------------------------------------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Monitoring NetScaler CPX Load Balancing Service & vServer with NITRO: | " -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------- " -ForegroundColor Yellow

    #region !! Adding a presentation demo break !!
    # ********************************************
    #    Read-Host 'Press Enter to continue…' | Out-Null
    #    Write-Host
    #endregion

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

        #region Get LB Services stats
            # Specifying the correct URL 
            $strURI = "http://$NSIP/nitro/v1/stat/service/svc_webserver_blue"

            # Method #1: Making the REST API call to the NetScaler
            $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#            Write-Host "response: " -ForegroundColor Green
#            $response.service | Select-Object name, primaryipaddress, primaryport, servicetype, state, totalrequests, cursrvrconnections, svrestablishedconn

            If ($response.service.state -ne "UP")
            {
                Write-Host ("Blue Service status is " + $response.service.state) -ForegroundColor Red
                ShowAlert -AlertTitle "Monitoring Blue webservice" -AlertMessage ("Blue webservice is " + $response.service.state)
            }
            Else
            {
#                Write-Host ("Blue Service status is UP!") -ForegroundColor Green
            }

        #endregion Get LB Services stats

        #region Get LB vServer stats
            # Specifying the correct URL 
            $strURI = "http://$NSIP/nitro/v1/stat/lbvserver?args=name:vsvr_webserver_81"

            # Method #1: Making the REST API call to the NetScaler
            $response = Invoke-RestMethod -Method Get -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#            Write-Host "response: " -ForegroundColor Green
#            $response.lbvserver | Select-object name, primaryipaddress, primaryport, type, state, vslbhealth, actsvcs, tothits

            If (($response.lbvserver.vslbhealth -ne 100) -and ($Alerted -eq $false))
            {
                Write-Host ("LB vServer runs at " + $response.lbvserver.vslbhealth + "% capacity!") -ForegroundColor Red
            }
            Else
            {
                Write-Host ("LB vServer runs at 100% capacity") -ForegroundColor Green
            }

        #endregion Add LB Services

        start-sleep -seconds $Interval
        # check https://msdn.microsoft.com/en-us/library/ee372287%28v=vs.110%29.aspx?f=255&MSPPError=-2147217396 for formatting options
        Write-Output ("Elapsed Time: " + $sw.Elapsed.ToString('hh\:mm\:ss'))
    }
    Write-Output "Time-out period of $Period seconds reached"

#region End NetScaler NITRO Session
    #Disconnect from the NetScaler VPX Virtual Appliance
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session
