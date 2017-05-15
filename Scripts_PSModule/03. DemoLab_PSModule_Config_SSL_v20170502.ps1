<#
.SYNOPSIS
  Configure Basic SSL Settings on the NetScaler VPX.
.DESCRIPTION
  Configure Basic SSL Settings (SF LB example) on the NetScaler VPX, using the PS-NITRO Module.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-05-04
  Purpose:        Created as part of the demo scripts for the PowerShell Conference EU 2017 in Hannover

  Copyright (c) cognition IT. All rights reserved.
#>
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

# --------------
# | SSL config |
# --------------
#region SSL Settings
If ($ConfigSSLSettings)
{
    Write-Host
    Write-Host "Starting SSL configuration: " -ForegroundColor Green

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

    #region Add certificate - key pairs
        Write-Host "Certificates in /nsconfig/ssl/ folder: " -ForegroundColor Yellow 
        (Get-NSSystemFile -NSSession $NSSession -NetScalerFolder "/nsconfig/ssl/" | Where-Object {((($_.filename -like "*.cert") -or ($_.filename -like "*.cer") -or ($_.filename -like "*.der") -or ($_.filename -like "*.pfx")) -and ($_.filename -notlike "ns-*"))})

        Add-NSSystemFile -NSSession $NSSession -PathToFile "$RootFolder\rootCA.cer" -NetScalerFolder "/nsconfig/ssl/" -ErrorAction SilentlyContinue
        Add-NSSystemFile -NSSession $NSSession -PathToFile "$RootFolder\Wildcard.pfx" -NetScalerFolder "/nsconfig/ssl/" -ErrorAction SilentlyContinue -Verbose:$true

        # keep in mind that the filenames are case-sensitive
        Add-NSSSLCertKey -NSSession $NSSession -CertKeyName "RootCA" -CertPath "/nsconfig/ssl/rootCA.cer" -CertKeyFormat PEM -ExpiryMonitor -NotificationPeriod 25 -ErrorAction SilentlyContinue
        Add-NSSSLCertKey -NSSession $NSSession -CertKeyName "wildcard.demo.lab" -CertPath "/nsconfig/ssl/Wildcard.pfx" -CertKeyFormat PFX -Password "password" -ErrorAction SilentlyContinue

        Write-Host "`n Certificate key pairs: " -ForegroundColor Yellow
        Get-NSSSLCertKey -NSSession $NSSession | Select-Object certkey, cert, key, inform, status, expirymonitor, notificationperiod | Where-Object {($_.certkey -notlike "ns-*")}
    #endregion

    #region Add certificate - links
        Add-NSSSLCertKeyLink -NSSession $NSSession -CertKeyName "wildcard.demo.lab" -LinkCertKeyName "RootCA" -ErrorAction SilentlyContinue
        Write-Host "Certificate links: " -ForegroundColor Yellow
        Get-NSSSLCertKeyLink -NSSession $NSSession -CertKeyName "wildcard.demo.lab"
    #endregion

    #region Bind Certificate to VServer
        Add-NSSSLVServerCertKeyBinding -NSSession $NSSession -VServerName vsvr_SFStore -CertKeyName "wildcard.demo.lab" -ErrorAction SilentlyContinue
        Write-Host "VServer certificate bindings: " -ForegroundColor Yellow
        Get-NSSSLVServerCertKeyBinding -NSSession $NSSession -VServerName vsvr_SFStore
    #endregion

    Write-Host 
    Write-Host "Finished SSL configuration: " -ForegroundColor Green
    Write-Host
}
#endregion

#region Final Step. Close the session to the NetScaler
    # restore SSL validation to normal behavior
    If ($RESTProtocol = "https")
    {
        Write-Verbose "Resetting Certificate Validation to default behavior"
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
    }
    # Disconnect the session to the NetScaler
    Disconnect-NSAppliance -NSSession $NSSession -ErrorAction SilentlyContinue
#endregion
