<#
.SYNOPSIS
  Configure Basic CS Settings on the NetScaler VPX.
.DESCRIPTION
  Configure Basic CS Settings (Unified Gateway example) on the NetScaler VPX, using the PS-NITRO Module.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-09-13
  Purpose:        Created as part of the test scripts for the New PowerShell Module setup

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
                $RootFolder = "G:\GitHub\PS-NITRO"
                $SubnetIP = "192.168.59"
            }
            default
            {
                $RootFolder = "C:\GitHub\PS-NITRO"
                $SubnetIP = "192.168.0"
            }
        }
        $NSLicFile = $RootFolder + "\NSVPX-ESX_PLT_201609.lic"

        # What to install (for script testing purposes)
        $ConfigCSSettings = $true
    #endregion Test Environment variables

    #region Import My PowerShell NITRO Module 
    If ((Get-Module -Name NitroConfigurationFunctions -ErrorAction SilentlyContinue) -eq $null)
    {
        Import-Module "$RootFolder\NitroModule" -Force
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
        $NSSession = Connect-NSAppliance -NSAddress $NSaddress -NSUserName $NSUsername -NSPassword $NSUserPW -Timeout 900
    #endregion
#endregion Script Settings

# --------------
# | CS config |
# --------------
#region CS Settings
If ($ConfigCSSettings)
{
    Write-Host
    Write-Host "Starting CS configuration: " -ForegroundColor Green

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

    #region Configure NetScaler Basic & Advanced Features to be enabled (NS - nsfeature)
        Enable-NSFeature -NSSession $NSSession -Feature "cs"
        Write-Host "Enabled Features: " -ForegroundColor Yellow
        (Get-NSFeature -NSSession $NSSession).feature
    #endregion

    #region Add CS vServer
         New-NSCSVServer -NSSession $NSSession -Name "cs_vsvr_one_url_test" -ServiceType SSL -IPAddressType IPAddress -IPAddress "192.168.0.13" -Port 443 -ClientTimeout 180 -Comment "created with NITRO" -ErrorAction SilentlyContinue

        Write-Host "`n Content Switch vServers: " -ForegroundColor Yellow
        Get-NSCSVServer -NSSession $NSSession | Select-Object name, ipv46, port, servicetype, curstate, status, clttimeout, comment
    #endregion

    #region Add CS Actions (bulk)
        # Add a Content Switch for the VPN vServer (using TargetVServer)
        New-NSCSAction -NSSession $NSSession -Name "cs_act_gateway" -TargetVServer "vsvr_nsg_demo_lab" -Comment "Created with NITRO" -ErrorAction SilentlyContinue
        # Add a Content Switch for the LB vServer (using TargetLBVServer)
        New-NSCSAction -NSSession $NSSession -Name "cs_act_storefront" -TargetLBVServer "vsvr_SFStore" -Comment "Created with NITRO" -ErrorAction SilentlyContinue

        Write-Host "`n Content Switch Actions: " -ForegroundColor Yellow
        Get-NSCSAction -NSSession $NSSession
    #endregion Add CS Actions

    #region Add CS Policies (bulk)
        New-NSCSPolicy -NSSession $NSSession -Name "cs_pol_gateway" -Rule "HTTP.REQ.HOSTNAME.SET_TEXT_MODE(IGNORECASE).EQ(""nsg.demo.lab"")" -Action "cs_act_gateway" -ErrorAction SilentlyContinue
        New-NSCSPolicy -NSSession $NSSession -Name "cs_pol_storefront" -Rule "HTTP.REQ.HOSTNAME.SET_TEXT_MODE(IGNORECASE).EQ(""sf.demo.lab"")" -Action "cs_act_storefront" -ErrorAction SilentlyContinue

        Write-Host "`n Content Switch Policies: " -ForegroundColor Yellow
        Get-NSCSPolicy -NSSession $NSSession | Select-Object policyname, rule, action, priority, cspolicytype
    #endregion Add CS Policies

    #region Bind CS Policies to vServer(bulk)
        New-NSCSVServerCSPolicyBinding -NSSession $NSSession -Name "cs_vsvr_one_url_test" -PolicyName "cs_pol_gateway" -Priority 100 -ErrorAction SilentlyContinue
        New-NSCSVServerCSPolicyBinding -NSSession $NSSession -Name "cs_vsvr_one_url_test" -PolicyName "cs_pol_storefront" -Priority 110 -ErrorAction SilentlyContinue

        Write-Host "`n CS vServer CS Policy bindings: " -ForegroundColor Yellow
        Get-NSCSVServerCSPolicyBinding -NSSession $NSSession -Name "cs_vsvr_one_url_test"
    #endregion Bind CS Policies to vServer

    #region Bind Certificate to vServer
        Add-NSSSLVServerCertKeyBinding -NSSession $NSSession -VServerName "cs_vsvr_one_url_test" -CertKeyName "wildcard.demo.lab" -ErrorAction SilentlyContinue
        Write-Host "VServer certificate bindings: " -ForegroundColor Yellow
        Get-NSSSLVServerCertKeyBinding -NSSession $NSSession -VServerName "cs_vsvr_one_url_test"
    #endregion Bind Certificate to VServer

    #region Add CS vServer for HTTP to HTTPS redirection
         New-NSCSVServer -NSSession $NSSession -Name "cs_vsvr_http_https_redirection" -ServiceType HTTP -IPAddressType IPAddress -IPAddress "192.168.0.13" -Port 80 -ClientTimeout 180 -Comment "created with NITRO - Carsten Bruns' tip for http to https redirection best practice" -ErrorAction SilentlyContinue

        Write-Host "`n Content Switch vServers: " -ForegroundColor Yellow
        Get-NSCSVServer -NSSession $NSSession -Name "cs_vsvr_http_https_redirection" | Select-Object name, ipv46, port, servicetype, curstate, status, clttimeout, comment
    #endregion Add CS Actions

    #region Bind Responder Policy to CS vServer
        New-NSCSVServerResponderPolicyBinding -NSSession $NSSession -Name "cs_vsvr_http_https_redirection" -PolicyName "rspp_http_https_redirect" -Priority 100 -GotoPriorityExpression "END" -Bindpoint REQUEST -ErrorAction SilentlyContinue

        Write-Host "`n CS vServer Responder Policy bindings: " -ForegroundColor Yellow
        Get-NSCSVServerResponderPolicyBinding -NSSession $NSSession -Name "cs_vsvr_http_https_redirection"
    #endregion Bind Responder Policy to vServer

    Write-Host 
    Write-Host "Finished CS configuration: " -ForegroundColor Green
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
