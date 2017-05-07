[CmdletBinding()]
# Declaring script parameters
Param()

#region Script settings
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
        $ConfigSSLSettings = $true
    #endregion Test Environment variables

    #region Import My PowerShell NITRO Module 
    If ((Get-Module -Name NitroConfigurationFunctions -ErrorAction SilentlyContinue) -eq $null)
    {
        Import-Module "$RootFolder\NitroConfigurationFunctions" -Force
    #    Write-Verbose -Message "Adding the cognitionIT developed NetScaler NITRO Configuration Functions PowerShell Module ..."
    }
    #endregion

    #region First session configurational settings and Start a session
        # Protocol to use for the REST API/NITRO call
        $RESTProtocol = "https"
        # NetScaler information for REST API call
        $NSaddress = ($SubnetIP+ ".2") # NSIP
        $NSUsername = "nsroot"
        $NSUserPW = "nsroot"
        # Connection protocol for the NetScaler
        Set-NSMgmtProtocol -Protocol $RESTProtocol

    # Force PowerShell to trust the NetScaler (self-signed) certificate
    If ($RESTProtocol = "https")
    {
        Write-Verbose "Forcing PowerShell to trust all certificates (including the self-signed netScaler certificate)"
        # source: https://blogs.technet.microsoft.com/bshukla/2010/04/12/ignoring-ssl-trust-in-powershell-system-net-webclient/ 
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    }

        # Start the session
        $NSSession = Connect-NSAppliance -NSAddress $NSaddress -NSUserName $NSUsername -NSPassword $NSUserPW
    #endregion
#endregion Script Settings

# ----------------------
# | Cleanup SSL config |
# ----------------------
#region Cleanup SSL Settings
If ($ConfigSSLSettings)
{
    Write-Host
    Write-Host "Cleaning up SSL configuration: " -ForegroundColor Green

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

    #region Remove certificate files
        Write-Host "Certificates in /nsconfig/ssl/ folder: " -ForegroundColor Yellow 
        (Get-NSSystemFile -NSSession $NSSession -NetScalerFolder "/nsconfig/ssl/" | Where-Object {((($_.filename -like "*.cert") -or ($_.filename -like "*.cer") -or ($_.filename -like "*.der") -or ($_.filename -like "*.pfx")) -and ($_.filename -notlike "ns-*"))})

        Remove-NSSystemFile -NSSession $NSSession -FileName "rootCA.cer" -NetScalerFolder "/nsconfig/ssl/" -ErrorAction SilentlyContinue
        Remove-NSSystemFile -NSSession $NSSession -FileName "Wildcard.pfx" -NetScalerFolder "/nsconfig/ssl/" -ErrorAction SilentlyContinue
        Remove-NSSystemFile -NSSession $NSSession -FileName "Wildcard.pfx.ns" -NetScalerFolder "/nsconfig/ssl/" -ErrorAction SilentlyContinue

        Write-Host "Certificate key pairs removed: " -ForegroundColor Yellow
        Get-NSSSLCertKey -NSSession $NSSession | Select-Object certkey, cert, key, inform, status, expirymonitor, notificationperiod | Where-Object {($_.certkey -notlike "ns-*")}
    #endregion

    Start-Sleep -Seconds 10

    #region Reboot NetScaler
    Restart-NSAppliance -NSSession $NSSession -WarmReboot
    #endregion reboot NetScaler

    Write-Host 
    Write-Host "Finished SSL configuration cleanup: " -ForegroundColor Green
    Write-Host
}
#endregion
