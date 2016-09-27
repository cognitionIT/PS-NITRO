[CmdletBinding()]
# Declaring script parameters
Param()

#region Test Environment variables
    $RootFolder = "H:\PSModules\NITRO\Scripts"
    $SubnetIP = "192.168.59"
    $NSLicFile = $RootFolder + "\NSVPX-ESX_PLT_201609.lic"

    # What to install (for script testing purposes)
    $ConfigFirstLogon = $true
    $ConfigBasicSettings = $true
    $ConfigAppExpertSettings = $true
    $ConfigTrafficManagementSettings = $true
    $ConfigSSLSettings = $true

#endregion

#region Import My PowerShell NITRO Module 
If ((Get-Module -Name NitroConfigurationFunctions -ErrorAction SilentlyContinue) -eq $null)
{
    Import-Module "$RootFolder\NitroConfigurationFunctions" -Force
}
#endregion

#region First session configurational settings and Start a session
    # Protocol to use for the REST API/NITRO call
    $RESTProtocol = "http"
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

# -------------------------------
# | First Logon (Wizard) config |
# -------------------------------
#region First GUI logon to NetScaler Management Console asks for:
If ($ConfigFirstLogon)
{
    Write-Host
    Write-Host "Starting First Logon (wizard) configuration: " -ForegroundColor Green

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
        Add-NSDnsNameServer -NSSession $NSSession -DNSServerIPAddress "192.168.0.1" -ErrorAction SilentlyContinue
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

    #region Configure NetScaler Modes to be enabled. (NS - nsmode)
        Enable-NSMode -NSSession $NSSession -Mode "FR Edge L3 USNIP PMTUD"
        Write-Host "Enabled Modes: " -ForegroundColor Yellow
        (Get-NSMode -NSSession $NSSession).mode
    #endregion

    #region Configure NetScaler Basic & Advanced Features to be enabled (NS - nsfeature)
        Enable-NSFeature -NSSession $NSSession -Feature "wl ssl lb cs gslb sslvpn rewrite responder"
        Write-Host "Enabled Features: " -ForegroundColor Yellow
        (Get-NSFeature -NSSession $NSSession).feature
    #endregion

    Write-Host "Finished Basic System Settings configuration: " -ForegroundColor Green
    Write-Host
}
#endregion


# ---------------------
# | App Expert config |
# ---------------------
#region Configure AppExpert Settings
If ($ConfigAppExpertSettings)
{
    Write-Host
    Write-Host "Starting App Expert configuration: " -ForegroundColor Green

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

    #region Configure Load Balancing - Servers
        Add-NSServer -NSSession $NSSession -Name "localhost" -IPAddress "127.0.0.1" -ErrorAction SilentlyContinue
        Add-NSServer -NSSession $NSSession -Name "SF2" -IPAddress ($SubnetIP + ".20") -ErrorAction SilentlyContinue
        Add-NSServer -NSSession $NSSession -Name "SF1" -IPAddress ($SubnetIP + ".1") -ErrorAction SilentlyContinue
        Write-Host "LB Servers: " -ForegroundColor Yellow -NoNewline
        Get-NSServer -NSSession $NSSession | Select-Object name,ipaddress,state | Format-List
    #endregion

    #region Configure Load Balancing - Services
        Add-NSService -NSSession $NSSession -Name "svc_local_http" -ServerName "localhost" -Protocol HTTP -Port 80 -ErrorAction SilentlyContinue
        Write-Host "LB Service: " -ForegroundColor Yellow -NoNewline
        Get-NSService -NSSession $NSSession -Name "svc_local_http" | Select-Object name,servername,servicetype,port,svrstate | Format-List
    #endregion

    #region Configure Load Balancing - Service Groups
        Add-NSServiceGroup -NSSession $NSSession -Name "svcgrp_SFStore" -Protocol HTTP -CacheType SERVER -Cacheable -State ENABLED -HealthMonitoring -AppflowLogging -AutoscaleMode DISABLED -ErrorAction SilentlyContinue
        New-NSServicegroupServicegroupmemberBinding -NSSession $NSSession -Name "svcgrp_SFStore" -ServerName "SF2" -Port 80 -State DISABLED -ErrorAction SilentlyContinue
        New-NSServicegroupServicegroupmemberBinding -NSSession $NSSession -Name "svcgrp_SFStore" -ServerName "SF1" -Port 80 -State ENABLED -ErrorAction SilentlyContinue
        Write-Host "LB Service Group: " -ForegroundColor Yellow -NoNewline
        Get-NSServicegroupServicegroupmemberBinding -NSSession $NSSession -Name "svcgrp_SFStore" | Select-Object servicegroupname,ip,port,svrstate,weight,servername,state
    #endregion
        
    #region Load Balancing - Monitors
        Add-NSLBMonitor -NSSession $NSSession -Name "lb_mon_SFStore" -Type STOREFRONT -State Enabled -ScriptName nssf.pl -LRTM -StoreName Store -ErrorAction SilentlyContinue
        Write-Host "LB Monitors: " -ForegroundColor Yellow -NoNewline
        Get-NSLBMonitor -NSSession $NSSession -Name "lb_mon_SFStore" | Select-Object monitorname,type,state,reverse, scriptname, storename, lrtm | Format-List

        New-NSServiceLBMonitorBinding -NSSession $NSSession -ServiceName "svc_local_http" -MonitorName "ping" -ErrorAction SilentlyContinue
        Write-Host "LB Service Monitor binding: " -ForegroundColor Yellow -NoNewline
        Get-NSServiceLBMonitorBinding -NSSession $NSSession -Name "svc_local_http"

        New-NSServicegroupLBMonitorBinding -NSSession $NSSession -ServicegroupName "svcgrp_SFStore" -MonitorName "lb_mon_SFStore" -ErrorAction SilentlyContinue
        Write-Host "LB Servicegroup Monitor binding: " -ForegroundColor Yellow
        Get-NSServicegroupLBMonitorBinding -NSSession $NSSession -Name "svcgrp_SFStore"
    #endregion

    #region Load Balancing - vServers
        Add-NSLBVServer -NSSession $NSSession -Name "vsvr_SFStore_http_redirect" -Protocol HTTP -IPAddressType IPAddress -IPAddress ($SubnetIP + ".101") -Port 80 -LBMethod LEASTCONNECTION  -ErrorAction SilentlyContinue
        Add-NSLBVServer -NSSession $NSSession -Name "vsvr_SFStore" -Protocol SSL -IPAddressType IPAddress -IPAddress ($SubnetIP + ".101") -Port 443 -LBMethod LEASTCONNECTION -ErrorAction SilentlyContinue
        Write-Host "LB vServer: " -ForegroundColor Yellow -NoNewline
        Get-NSLBVServer -NSSession $NSSession | Select-Object name,ipv46, port, servicetype, effectivestate, status | Format-List

        New-NSLBVServerServicegroupBinding -NSSession $NSSession -Name "vsvr_SFStore" -ServiceGroupName "svcgrp_SFStore" -ErrorAction SilentlyContinue
        New-NSLBVServerServiceBinding -NSSession $NSSession -Name "vsvr_SFStore_http_redirect" -ServiceName "svc_local_http" -ErrorAction SilentlyContinue
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


# --------------
# | SSL config |
# --------------
#region SSL Settings
If ($ConfigSSLSettings)
{
    Write-Host
    Write-Host "Starting SSL configuration: " -ForegroundColor Green

    #region Add certificate - key pairs
        Write-Host "Certificates in /nsconfig/ssl/ folder: " -ForegroundColor Yellow 
        (Get-NSSystemFile -NSSession $NSSession -NetScalerFolder "/nsconfig/ssl/" | Where-Object {((($_.filename -like "*.cert") -or ($_.filename -like "*.cer") -or ($_.filename -like "*.der") -or ($_.filename -like "*.pfx")) -and ($_.filename -notlike "ns-*"))})

        Add-NSSystemFile -NSSession $NSSession -PathToFile "$RootFolder\rootCA.cer" -NetScalerFolder "/nsconfig/ssl/" -ErrorAction SilentlyContinue
        Add-NSSystemFile -NSSession $NSSession -PathToFile "$RootFolder\Wildcard.pfx" -NetScalerFolder "/nsconfig/ssl/" -ErrorAction SilentlyContinue

        # keep in mind that the filenames are case-sensitive
        Add-NSSSLCertKey -NSSession $NSSession -CertKeyName "RootCA" -CertPath "/nsconfig/ssl/rootCA.cer" -CertKeyFormat PEM -ExpiryMonitor -NotificationPeriod 25 -ErrorAction SilentlyContinue
        Add-NSSSLCertKey -NSSession $NSSession -CertKeyName "wildcard.demo.lab" -CertPath "/nsconfig/ssl/Wildcard.pfx" -CertKeyFormat PFX -Password "password" -ErrorAction SilentlyContinue

        Write-Host "Certificate key pairs: " -ForegroundColor Yellow
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
        #Remove-NSSSLVServerCertKeyBinding -NSSession $NSSession -VServerName vsvr_SFStore -CertKeyName "wildcard.demo.lab" -Verbose
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

