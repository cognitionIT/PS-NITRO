<#
.SYNOPSIS
  Configure Basic Load Balancing Settings on the NetScaler VPX.
.DESCRIPTION
  Configure Basic Load Balancing Settings (SF LB example) on the NetScaler VPX, using the PS-NITRO Module.
.NOTES
  Version:        1.1
  Author:         Esther Barthel, MSc
  Creation Date:  2017-05-04
  Purpose:        Created as part of the demo scripts for the PowerShell Conference EU 2017 in Hannover
  Updated:        2017-08-18
  Purpose:        Added improved svc_alwaysUP configuration for HTTP to HTTPS redirection
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
                $RootFolder = "C:\GitHub\PS-NITRO"
                $SubnetIP = "192.168.0"
            }
        }
        $NSLicFile = $RootFolder + "\NSVPX-ESX_PLT_201609.lic"

        # What to install (for script testing purposes)
        $ConfigAppExpertSettings = $true
        $ConfigTrafficManagementSettings = $true

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
        $NSaddress = ($SubnetIP+ ".2") # NSIP
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

# ---------------------
# | App Expert config |
# ---------------------
#region Configure AppExpert Settings
If ($ConfigAppExpertSettings)
{
    Write-Host
    Write-Host "Starting App Expert configuration: " -ForegroundColor Green

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

    Add-NSRewriteAction -NSSession $NSSession -ActionName "rwa_store_redirect" -ActionType "replace" -TargetExpression "HTTP.REQ.URL" -Expression """/Citrix/StoreWeb""" -ErrorAction SilentlyContinue
    Write-Host "Rewrite Actions: " -ForegroundColor Yellow -NoNewline
    Get-NSRewriteAction -NSSession $NSSession -ActionName "rwa_store_redirect" | Select-Object name, type, stringbuilderexpr, isdefault | Format-List

    Add-NSRewritePolicy -NSSession $NSSession -PolicyName "rwp_store_redirect" -PolicyAction "rwa_store_redirect" -PolicyRule "HTTP.REQ.URL.EQ(""/"")" -ErrorAction SilentlyContinue
    Write-Host "Rewrite Policies: " -ForegroundColor Yellow -NoNewline
    Get-NSRewritePolicy -NSSession $NSSession -PolicyName "rwp_store_redirect" | Select-Object name, rule, action, isdefault | Format-List

    Add-NSResponderAction -NSSession $NSSession -ActionName "rspa_http_https_redirect" -ActionType "redirect" -TargetExpression """https://"" + HTTP.REQ.HOSTNAME.HTTP_URL_SAFE + HTTP.REQ.URL.PATH_AND_QUERY.HTTP_URL_SAFE" -ResponseStatusCode 302 -ErrorAction SilentlyContinue
    Write-Host "Responder Actions: " -ForegroundColor Yellow -NoNewline
    Get-NSResponderAction -NSSession $NSSession | Select-Object name, type, target, responsestatuscode | Format-List

    Add-NSResponderPolicy -NSSession $NSSession -Name "rspp_http_https_redirect" -Rule "HTTP.REQ.IS_VALID" -Action "rspa_http_https_redirect" -ErrorAction SilentlyContinue
    Write-Host "Responder Policies: " -ForegroundColor Yellow -NoNewline
    Get-NSResponderPolicy -NSSession $NSSession | Select-Object name, rule, action, priority | Format-List

    Write-Host "Finished App Expert configuration: " -ForegroundColor Green
    Write-Host
}
#endregion

# -----------------------------
# | Traffic Management config |
# -----------------------------
#region Traffic Management Settings
If ($ConfigTrafficManagementSettings)
{
    Write-Host
    Write-Host "Starting Traffic Management (Load Balancing) configuration: " -ForegroundColor Green

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

    #region Configure Load Balancing - Servers
        Add-NSServer -NSSession $NSSession -Name "svr_alwaysUP" -IPAddress "1.1.1.1" -ErrorAction SilentlyContinue
        Add-NSServer -NSSession $NSSession -Name "SF2" -IPAddress ($SubnetIP + ".22") -ErrorAction SilentlyContinue
        Add-NSServer -NSSession $NSSession -Name "SF1" -IPAddress ($SubnetIP + ".21") -ErrorAction SilentlyContinue
        Write-Host "LB Servers: " -ForegroundColor Yellow -NoNewline
        Get-NSServer -NSSession $NSSession | Select-Object name,ipaddress,state | Format-List
    #endregion

    #region Configure Load Balancing - Services
        Add-NSService -NSSession $NSSession -Name "svc_alwaysUP" -ServerName "svr_alwaysUP" -Protocol HTTP -Port 80 -HealthMonitoring NO -ErrorAction SilentlyContinue
        Write-Host "LB Service: " -ForegroundColor Yellow -NoNewline
        Get-NSService -NSSession $NSSession -Name "svc_alwaysUP" | Select-Object name,servername,servicetype,port,healthmonitoring,svrstate | Format-List
    #endregion

    #region Configure Load Balancing - Service Groups
        Add-NSServiceGroup -NSSession $NSSession -Name "svcgrp_SFStore" -Protocol HTTP -CacheType SERVER -Cacheable -State ENABLED -HealthMonitoring YES -AppflowLogging -AutoscaleMode DISABLED -ErrorAction SilentlyContinue
        New-NSServicegroupServicegroupmemberBinding -NSSession $NSSession -Name "svcgrp_SFStore" -ServerName "SF2" -Port 80 -State ENABLED -Weight 2 -ErrorAction SilentlyContinue
        New-NSServicegroupServicegroupmemberBinding -NSSession $NSSession -Name "svcgrp_SFStore" -ServerName "SF1" -Port 80 -State ENABLED -Weight 1 -ErrorAction SilentlyContinue
        Write-Host "LB Service Group: " -ForegroundColor Yellow -NoNewline
        Get-NSServicegroupServicegroupmemberBinding -NSSession $NSSession -Name "svcgrp_SFStore" | Select-Object servicegroupname,ip,port,svrstate,weight,servername,state,healthmonitoring
    #endregion
        
    #region Load Balancing - Monitors
        Add-NSLBMonitor -NSSession $NSSession -Name "lb_mon_SFStore" -Type STOREFRONT -State Enabled -ScriptName nssf.pl -LRTM -StoreName Store -ErrorAction SilentlyContinue
        Write-Host "LB Monitors: " -ForegroundColor Yellow -NoNewline
        Get-NSLBMonitor -NSSession $NSSession -Name "lb_mon_SFStore" | Select-Object monitorname,type,state,reverse, scriptname, storename, lrtm | Format-List

        New-NSServicegroupLBMonitorBinding -NSSession $NSSession -ServicegroupName "svcgrp_SFStore" -MonitorName "ping" -ErrorAction SilentlyContinue
        New-NSServicegroupLBMonitorBinding -NSSession $NSSession -ServicegroupName "svcgrp_SFStore" -MonitorName "lb_mon_SFStore" -ErrorAction SilentlyContinue

        Remove-NSServicegroupLBMonitorBinding -NSSession $NSSession -ServicegroupName "svcgrp_SFStore" -MonitorName "ping"
        Write-Host "LB Servicegroup Monitor binding: " -ForegroundColor Yellow
        Get-NSServicegroupLBMonitorBinding -NSSession $NSSession -Name "svcgrp_SFStore"
    #endregion

    #region Load Balancing - vServers
        Add-NSLBVServer -NSSession $NSSession -Name "vsvr_SFStore_http_redirect" -Protocol HTTP -IPAddressType IPAddress -IPAddress ($SubnetIP + ".11") -Port 80 -LBMethod ROUNDROBIN  -ErrorAction SilentlyContinue
        Add-NSLBVServer -NSSession $NSSession -Name "vsvr_SFStore" -Protocol SSL -IPAddressType IPAddress -IPAddress ($SubnetIP + ".11") -Port 443 -LBMethod ROUNDROBIN -ErrorAction SilentlyContinue
        Write-Host "LB vServer: " -ForegroundColor Yellow -NoNewline
        Get-NSLBVServer -NSSession $NSSession | Select-Object name,ipv46, port, servicetype, effectivestate, status | Format-List

        New-NSLBVServerServicegroupBinding -NSSession $NSSession -Name "vsvr_SFStore" -ServiceGroupName "svcgrp_SFStore" -ErrorAction SilentlyContinue
        New-NSLBVServerServiceBinding -NSSession $NSSession -Name "vsvr_SFStore_http_redirect" -ServiceName "svc_alwaysUP" -ErrorAction SilentlyContinue
        Write-Host "LB vServer Service Group binding: " -ForegroundColor Yellow -NoNewline
        Get-NSLBVServerServicegroupBinding -NSSession $NSSession -Name "vsvr_SFStore" | Select-Object name, servicename, servicegroupname, ipv46, port, servicetype, curstate | Format-List
        Get-NSLBVServerServiceBinding -NSSession $NSSession -Name "vsvr_SFStore_http_redirect" | Select-Object name, servicename, servicegroupname, ipv46, port, servicetype, curstate | Format-List

        New-NSLBVServerResponderPolicyBinding -NSSession $NSSession -vServerName "vsvr_SFStore_http_redirect" -PolicyName "rspp_http_https_redirect" -Priority 100 -GotoPriorityExpression "END" -ErrorAction SilentlyContinue
        Write-Host "LB vServer Responder Policy binding: " -ForegroundColor Yellow -NoNewline
        Get-NSLBVServerResponderPolicyBinding -NSSession $NSSession -Name "vsvr_SFStore_http_redirect" | Select-Object name, policyname, priority, gotopriorityexpression, invoke | Format-List

        New-NSLBVServerRewritePolicyBinding -NSSession $NSSession -vServerName "vsvr_SFStore" -PolicyName "rwp_store_redirect" -Priority 100 -GotoPriorityExpression "END" -BindPoint REQUEST -ErrorAction SilentlyContinue
        Write-Host "LB vServer Rewrite Policy binding: " -ForegroundColor Yellow -NoNewline
        Get-NSLBVServerRewritePolicyBinding -NSSession $NSSession -Name "vsvr_SFStore" | Select-Object name, policyname, priority, gotopriorityexpression, invoke | Format-List
    #endregion

    Write-Host "Finished Traffic Management (Load Balancing) configuration: " -ForegroundColor Green
    Write-Host
}
#endregion

#region Final Step. Close the session to the NetScaler
    # extra cleaning rule for demo purposes
    Remove-NSServicegroupLBMonitorBinding -NSSession $NSSession -ServicegroupName "svcgrp_SFStore" -MonitorName "lb_mon_SFStore"

    # restore SSL validation to normal behavior
    If ($RESTProtocol = "https")
    {
        Write-Verbose "Resetting Certificate Validation to default behavior"
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
    }

    # Disconnect the session to the NetScaler
    Disconnect-NSAppliance -NSSession $NSSession -ErrorAction SilentlyContinue
#endregion
