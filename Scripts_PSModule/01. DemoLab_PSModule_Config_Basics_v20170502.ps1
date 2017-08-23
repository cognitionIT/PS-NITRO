<#
.SYNOPSIS
  Configure Basic System Settings on the NetScaler VPX.
.DESCRIPTION
  Configure Basic System Settings (First Logon Wizard, Modes, Features) on the NetScaler VPX, using the PS-NITRO Module.
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

#region Script Settings
    #region Test Environment variables
        $TestEnvironment = "demo"

        Switch ($TestEnvironment)
        {
            "Elektra" 
            {
                $RootFolder = "G:\GitHub\PS-NITRO"
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
        $ConfigFirstLogon = $true
        $ConfigBasicSettings = $true

    #endregion

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
        $NSaddress = ($SubnetIP + ".2") # NSIP
        $NSUsername = "nsroot"
        $NSUserPW = "nsroot"
        # Connection protocol for the NetScaler
        Set-NSMgmtProtocol -Protocol $RESTProtocol
    #endregion
    #region Force PowerShell to trust the NetScaler (self-signed) certificate
    If ($RESTProtocol = "https")
    {
        Write-Verbose "Forcing PowerShell to trust all certificates (including the self-signed netScaler certificate)"
        # source: https://blogs.technet.microsoft.com/bshukla/2010/04/12/ignoring-ssl-trust-in-powershell-system-net-webclient/ 
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    }
    #endregion
#endregion Script Settings

#region Start the session
    $NSSession = Connect-NSAppliance -NSAddress $NSaddress -NSUserName $NSUsername -NSPassword $NSUserPW
#endregion

# -------------------------------
# | First Logon (Wizard) config |
# -------------------------------
#region First GUI logon to NetScaler Management Console asks for:
If ($ConfigFirstLogon)
{
    Write-Host
    Write-Host "Starting First Logon (wizard) configuration: " -ForegroundColor Green

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

    #region Step 0. Disable Citrix User Experience Improvement Program (CEIP):
        Disable-NSCEIP -NSSession $NSSession
        Write-Host "CEIP Status: " -ForegroundColor Yellow -NoNewline
        Write-Host (Get-NSCEIP -NSSession $NSSession)
    #endregion

    #region Step 1. NSIP is configured with the import script
        Write-Host "NetScaler IP: " -ForegroundColor Yellow -NoNewline
        Write-Host (Get-NSIPResource -NSSession $NSSession | Select-Object ipaddress,type,mgmtaccess,state)
    #endregion

    #region Step 2. SNIP (NS - nsip)
        Add-NSIPResource -NSSession $NSSession -IPAddress ($SubnetIP+ ".3") -SubnetMask "255.255.255.0" -Type SNIP -ErrorAction SilentlyContinue
        Write-Host "Subnet IP Addresses: " -ForegroundColor Yellow -NoNewline
        Write-Host (Get-NSIPResource -NSSession $NSSession | Select-Object ipaddress,type,mgmtaccess,state | Where-Object {$_.type -eq "SNIP"} )
    #endregion

    #region Step 3a. Hostname (NS - nshostname)
        Set-NSHostName -NSSession $NSSession -HostName "NSNitroDemo"
        Write-Host "NS Hostname: " -ForegroundColor Yellow -NoNewline
        Write-Host (Get-NSHostName -NSSession $NSSession)
    #endregion

    #region Step 3b. DNS Server IP Address (Domain Name Service - dnsnameserver)
        Add-NSDnsNameServer -NSSession $NSSession -DNSServerIPAddress ($SubnetIP + ".1") -ErrorAction SilentlyContinue
        Write-Host "DNS Name Server: " -ForegroundColor Yellow -NoNewline
        Write-Host (Get-NSDnsNameServer -NSSession $NSSession | Select-Object ip, port, type, state, nameserverstate)
    #endregion

    #region Step 3c. Time Zone (NS - nsconfig)
        Set-NSTimeZone -NSSession $NSSession -TimeZone "GMT+01:00-CET-Europe/Amsterdam"
        Write-Host "Timezone: " -ForegroundColor Yellow -NoNewline
        Write-Host (Get-NSTimeZone -NSSession $NSSession)
    #endregion

    #region Step 4. Retrieve the License information (System - systemfile)
        Write-Host "License info: " -ForegroundColor Yellow -NoNewline
        Write-Host (Get-NSLicenseInfo -NSSession $NSSession | Select-Object modelid, isstandardlic,isenterpriselic,isplatinumlic)
    #endregion
    Write-Host "Finished First Logon (wizard) configuration: " -ForegroundColor Green
    Write-Host
}
#endregion

# -----------------------------------
# | NetScaler Basic System Settings |
# -----------------------------------
#region Set NetScaler Basic settings
If ($ConfigBasicSettings)
{
    Write-Host
    Write-Host "Starting Basic System Settings configuration: " -ForegroundColor Green

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

    #region Configure NetScaler Modes to be enabled. (NS - nsmode)
        Enable-NSMode -NSSession $NSSession -Mode "FR Edge L3 USNIP PMTUD"
        Write-Host "Enabled Modes: " -ForegroundColor Yellow
        (Get-NSMode -NSSession $NSSession).mode
    #endregion

    #region Configure NetScaler Basic & Advanced Features to be enabled (NS - nsfeature)
        Enable-NSFeature -NSSession $NSSession -Feature "lb ssl sslvpn rewrite responder cs"
        Write-Host "Enabled Features: " -ForegroundColor Yellow
        (Get-NSFeature -NSSession $NSSession).feature
    #endregion

    Write-Host "Finished Basic System Settings configuration: " -ForegroundColor Green
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
