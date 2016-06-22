[CmdletBinding()]
# Declaring script parameters
Param()

#region Import My PowerShell NITRO Module 
If ((Get-Module -Name NitroConfigurationFunctions -ErrorAction SilentlyContinue) -eq $null)
{
    Import-Module "H:\PSModules\NITRO\Scripts\NitroConfigurationFunctions" -Force
    Write-Verbose -Message "Adding the cognitionIT developed NetScaler NITRO Configuration Functions PowerShell Module ..." -Verbose:$VerbosePreference
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

# ---------------------
# | App Expert config |
# ---------------------

#region Configure AppExpert Settings
    Add-NSRewriteAction -NSSession $NSSession -ActionName "rwa_store_redirect" -ActionType "replace" -TargetExpression "HTTP.REQ.URL" -Expression """/Citrix/Store"""
    Write-Host "Rewrite Actions: " -ForegroundColor Yellow -NoNewline
    Get-NSRewriteAction -NSSession $NSSession -ActionName "rwa_store_redirect" | Select-Object name, type, stringbuilderexpr, isdefault | Format-List

    Add-NSRewritePolicy -NSSession $NSSession -PolicyName "rwp_store_redirect" -PolicyAction "rwa_store_redirect" -PolicyRule "HTTP.REQ.URL.EQ(""/"")"
    Write-Host "Rewrite Policies: " -ForegroundColor Yellow -NoNewline
    Get-NSRewritePolicy -NSSession $NSSession -PolicyName "rwp_store_redirect" | Select-Object name, rule, action, isdefault | Format-List

    Add-NSResponderAction -NSSession $NSSession -ActionName "rspa_http_https_redirect" -ActionType "redirect" -TargetExpression """https://"" + HTTP.REQ.HOSTNAME.HTTP_URL_SAFE + HTTP.REQ.URL.PATH_AND_QUERY.HTTP_URL_SAFE" -ResponseStatusCode 302
    Write-Host "Responder Actions: " -ForegroundColor Yellow -NoNewline
    Get-NSResponderAction -NSSession $NSSession | Select-Object name, type, target, responsestatuscode | Format-List

    Add-NSResponderPolicy -NSSession $NSSession -Name "rspp_http_https_redirect" -Rule "HTTP.REQ.IS_VALID" -Action "rspa_http_https_redirect"
    Write-Host "Responder Policies: " -ForegroundColor Yellow -NoNewline
    Get-NSResponderPolicy -NSSession $NSSession | Select-Object name, rule, action, priority | Format-List
#endregion

# -----------------------------
# | Traffic Management config |
# -----------------------------

#region Configure Load Balancing - Servers
    Add-NSServer -NSSession $NSSession -Name "localhost" -IPAddress "127.0.0.1"
    Add-NSServer -NSSession $NSSession -Name "SF1" -IPAddress "192.168.10.20"
    Add-NSServer -NSSession $NSSession -Name "SF2" -IPAddress "192.168.10.21"
    Write-Host "LB Servers: " -ForegroundColor Yellow -NoNewline
    Get-NSServer -NSSession $NSSession | Select-Object name,ipaddress,state | Format-List
#endregion

#region Configure Load Balancing - Services
    Add-NSService -NSSession $NSSession -Name "svc_local_http" -ServerName "localhost" -Protocol HTTP -Port 80
    Write-Host "LB Services: " -ForegroundColor Yellow -NoNewline
    Get-NSService -NSSession $NSSession -Name "svc_local_http" | Select-Object name,servername,servicetype,port,svrstate | Format-List
#endregion

#region Configure Load Balancing - Service Groups
    Add-NSServiceGroup -NSSession $NSSession -Name "svcgrp_SFStore" -Protocol HTTP -CacheType SERVER -Cacheable -State ENABLED -HealthMonitoring -AppflowLogging -AutoscaleMode DISABLED
    New-NSServicegroupServicegroupmemberBinding -NSSession $NSSession -Name "svcgrp_SFStore" -ServerName "SF1" -Port 80 -State DISABLED
    New-NSServicegroupServicegroupmemberBinding -NSSession $NSSession -Name "svcgrp_SFStore" -ServerName "SF2" -Port 80 -State ENABLED
    Write-Host "LB Service Groups: " -ForegroundColor Yellow -NoNewline
    Get-NSServicegroupServicegroupmemberBinding -NSSession $NSSession -Name "svcgrp_SFStore" | Select-Object servicegroupname,ip,port,svrstate,weight,servername,state
#endregion

#region Load Balancing - Monitors
    Add-NSLBMonitor -NSSession $NSSession -Name "lb_mon_SFStore" -Type STOREFRONT -State Enabled -ScriptName nssf.pl -LRTM -StoreName Store1
    Write-Host "LB Monitors: " -ForegroundColor Yellow -NoNewline
    Get-NSLBMonitor -NSSession $NSSession -Name "lb_mon_SFStore" | Select-Object monitorname,type,state,reverse, scriptname, storename, lrtm | Format-List
#endregion

    #region Load Balancing - vServers
    Add-NSLBVServer -NSSession $NSSession -Name "vsvr_SFStore_http_redirect" -Protocol HTTP -IPAddressType IPAddress -IPAddress "192.168.10.102" -Port 80 -LBMethod LEASTCONNECTION 
    Add-NSLBVServer -NSSession $NSSession -Name "vsvr_SFStore" -Protocol SSL -IPAddressType IPAddress -IPAddress "192.168.10.101" -Port 80 -LBMethod LEASTCONNECTION 
    Write-Host "LB vServer: " -ForegroundColor Yellow -NoNewline
    Get-NSLBVServer -NSSession $NSSession | Select-Object name,ipv46, port, servicetype, effectivestate, status | Format-List

    New-NSLBVServerServicegroupBinding -NSSession $NSSession -Name "vsvr_SFStore" -ServiceGroupName "svcgrp_SFStore"
    New-NSLBVServerServiceBinding -NSSession $NSSession -Name "vsvr_SFStore_http_redirect" -ServiceName "svc_local_http"
    Write-Host "LB vServer Service Group binding: " -ForegroundColor Yellow -NoNewline
    Get-NSLBVServerServicegroupBinding -NSSession $NSSession -Name "vsvr_SFStore" | Select-Object name, servicename, servicegroupname, ipv46, port, servicetype, curstate | Format-List
    Get-NSLBVServerServiceBinding -NSSession $NSSession -Name "vsvr_SFStore_http_redirect" | Select-Object name, servicename, servicegroupname, ipv46, port, servicetype, curstate | Format-List

    New-NSLBVServerResponderPolicyBinding -NSSession $NSSession -vServerName "vsvr_SFStore_http_redirect" -PolicyName "rspp_http_https_redirect" -Priority 100 -GotoPriorityExpression "END"
    Write-Host "LB vServer Responder Policy binding: " -ForegroundColor Yellow -NoNewline
    Get-NSLBVServerResponderPolicyBinding -NSSession $NSSession -Name "vsvr_SFStore_http_redirect" | Select-Object name, policyname, priority, gotopriorityexpression, invoke | Format-List

    New-NSLBVServerRewritePolicyBinding -NSSession $NSSession -vServerName "vsvr_SFStore" -PolicyName "rwp_store_redirect" -Priority 100 -GotoPriorityExpression "END" -BindPoint REQUEST
    Write-Host "LB vServer Rewrite Policy binding: " -ForegroundColor Yellow -NoNewline
    Get-NSLBVServerRewritePolicyBinding -NSSession $NSSession -Name "vsvr_SFStore" | Select-Object name, policyname, priority, gotopriorityexpression, invoke | Format-List
#endregion

