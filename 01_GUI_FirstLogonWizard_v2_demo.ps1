[CmdletBinding()]
# Declaring script parameters
Param()

#region Import My PowerShell NITRO Module 
If ((Get-Module -Name NitroConfigurationFunctions -ErrorAction SilentlyContinue) -eq $null)
{
    Import-Module "H:\PSModules\NITRO\Scripts\NitroConfigurationFunctions" -Force
#    Write-Verbose -Message "Adding the cognitionIT developed NetScaler NITRO Configuration Functions PowerShell Module ..."
}
#endregion
#region First session configurational settings and Start a session
    # Protocol to use for the REST API/NITRO call
    $RESTProtocol = "http"
    # NetScaler information for REST API call
    $NSaddress = "192.168.10.6" # NSIP
    $NSUsername = "nsroot"
    $NSUserPW = "nsroot"
    # Connection protocol for the NetScaler
    Set-NSMgmtProtocol -Protocol $RESTProtocol

    # Start the session
    $NSSession = Connect-NSAppliance -NSAddress $NSaddress -NSUserName $NSUsername -NSPassword $NSUserPW
#endregion

# -------------------------------
# | First Logon (Wizard) config |
# -------------------------------

#region First GUI logon to NetScaler Management Console asks for:

    #region Step 0. Enable (or disable) Citrix User Experience Improvement Program (CEIP):
        Disable-NSCEIP -NSSession $NSSession
        Write-Host "CEIP Status: " -ForegroundColor Yellow -NoNewline
        Write-Host (Get-NSCEIP -NSSession $NSSession)
    #endregion

    #region Step 1. NSIP is configured with the import script
        Write-Host "NetScaler IP: " -ForegroundColor Yellow -NoNewline
        Write-Host (Get-NSIPResource -NSSession $NSSession | Select-Object ipaddress,type,mgmtaccess,state)
    #endregion

    #region Step 2. SNIP (NS - nsip)
        Add-NSIPResource -NSSession $NSSession -IPAddress "192.168.10.7" -SubnetMask "255.255.255.0" -Type SNIP
        Write-Host "Subnet IP Addresses: " -ForegroundColor Yellow -NoNewline
        Write-Host (Get-NSIPResource -NSSession $NSSession | Select-Object ipaddress,type,mgmtaccess,state | Where-Object {$_.type -eq "SNIP"} )
    #endregion

    #region Step 3a. Hostname (NS - nshostname)
        Set-NSHostName -NSSession $NSSession -HostName "NSNitro"
        Write-Host "NS Hostname: " -ForegroundColor Yellow -NoNewline
        Write-Host (Get-NSHostName -NSSession $NSSession)
    #endregion

    #region Step 3b. DNS Server IP Address (Domain Name Service - dnsnameserver)
        Add-NSDnsNameServer -NSSession $NSSession -DNSServerIPAddress "192.168.10.1"
        Write-Host "DNS Name Server: " -ForegroundColor Yellow -NoNewline
        Write-Host (Get-NSDnsNameServer -NSSession $NSSession | Select-Object ip, port, type, state, nameserverstate)
    #endregion

    #region Step 3c. Time Zone (NS - nsconfig)
        Set-NSTimeZone -NSSession $NSSession -TimeZone "GMT+01:00-CET-Europe/Amsterdam"
        Write-Host "Timezone: " -ForegroundColor Yellow -NoNewline
        Write-Host (Get-NSTimeZone -NSSession $NSSession)
    #endregion

    #region Step 4. Upload the License File (System - systemfile)
#        Send-NSLicense -NSSession $NSSession -PathToLicenseFile "H:\PSModules\NITRO\Scripts\XenServer\NSVPX1000_PLT_1yr_license_feb17_1e718a76f16e.lic"
        Write-Host "License info: " -ForegroundColor Yellow -NoNewline
        Write-Host (Get-NSLicense -NSSession $NSSession | Select-Object modelid, isstandardlic,isenterpriselic,isplatinumlic)
        # NOTE: A (warm) reboot is required to reread the license file and save the configuration
        # Restart the session after the warm reboot (optional save config before reboot)
#        Restart-NSAppliance -NSSession $NSSession -WarmReboot -SaveNSConfig
    #endregion
#endregion
