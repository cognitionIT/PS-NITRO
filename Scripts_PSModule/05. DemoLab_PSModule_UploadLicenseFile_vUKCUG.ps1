<#
.SYNOPSIS
  Configure Basic System Settings on the NetScaler VPX.
.DESCRIPTION
  Configure Basic System Settings (First Logon Wizard, Modes, Features) on the NetScaler VPX, using the Invoke-RestMethod cmdlet for the REST API calls.
.NOTES
  Version:        1.1
  Author:         Esther Barthel, MSc
  Creation Date:  2017-05-04
  Purpose:        Created as part of the demo scripts for the UKCUG presentation
  Update:         2017-09-05
  Purpose:        Improved script functionality

  Copyright (c) cognition IT. All rights reserved.
#>
[CmdletBinding()]
# Declaring script parameters
Param()

#region Test Environment variables
    $RootFolder = "C:\GitHub\PS-NITRO"
    $SubnetIP = "192.168.0"
    $NSLicFile = "C:\Input\LicenseFiles\NSVPX-ESX_PLT_201609.lic"

    # NetScaler information for REST API call
    $NSaddress = ($SubnetIP+ ".202") # NSIP
    $NSUsername = "nsroot"
    $NSUserPW = "nsroot"

    # What to install (for script testing purposes)
    $ConfigUploadLicense = $true

#endregion

#region Import My PowerShell NITRO Module 
If ((Get-Module -Name NitroConfigurationFunctions -ErrorAction SilentlyContinue) -eq $null)
{
    Import-Module "$RootFolder\NitroConfigurationFunctions" -Force
}
Else
{
    Remove-Module -Name NitroConfigurationFunctions -ErrorAction SilentlyContinue
    Import-Module "$RootFolder\NitroConfigurationFunctions" -Force
}
#endregion

#region First session configurational settings and Start a session
    # Protocol to use for the REST API/NITRO call
    $RESTProtocol = "http"
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

Write-Host "--------------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Uploading license file to NetScaler with NITRO: | " -ForegroundColor Yellow
Write-Host "--------------------------------------------------- " -ForegroundColor Yellow

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion


# ----------------------
# |Upload License File |
# ----------------------
#region First GUI logon to NetScaler Management Console asks for:
If ($ConfigFirstLogon)
{
    Write-Host
    Write-Host "Starting License File upload: " -ForegroundColor Green

    #region Step 4. Upload the License File (System - systemfile)
        If ($ConfigUploadLicense)
        {
            # Check if license exists
            Get-NSLicenseInfo -NSSession $NSSession
            
            Write-Host "Uploading license file $NSLicFile to the NetScaler" -ForegroundColor Yellow
            Send-NSLicense -NSSession $NSSession -PathToLicenseFile $NSLicFile -ErrorAction SilentlyContinue
            Write-Host "License info: " -ForegroundColor Yellow -NoNewline
            Write-Host (Get-NSLicenseInfo -NSSession $NSSession | Select-Object modelid, isstandardlic,isenterpriselic,isplatinumlic)

            # NOTE: A (warm) reboot is required to reread the license file and save the configuration
            Write-Host "Sending a warm reboot (without config safe) to the NetScaler" -ForegroundColor Yellow
            Restart-NSAppliance -NSSession $NSSession -WarmReboot
            #endregion
        }
        Else
        {
            Write-Host "License info: " -ForegroundColor Yellow -NoNewline
            Write-Host (Get-NSLicenseInfo -NSSession $NSSession | Select-Object modelid, isstandardlic,isenterpriselic,isplatinumlic)
        }
    #endregion
    Write-Host "Finished License File upload!" -ForegroundColor Green
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
