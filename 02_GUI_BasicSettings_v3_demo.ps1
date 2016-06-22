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

# -------------------------
# | Basic Settings config |
# -------------------------

#region Set NetScaler Basic settings

    #region Configure NetScaler Modes to be enabled. (NS - nsmode)
        Enable-NSMode -NSSession $NSSession -Mode "FR Edge L3 USNIP PMTUD"
    #endregion
    #region Configure NetScaler Basic & Advanced Features to be enabled (NS - nsfeature)
        Enable-NSFeature -NSSession $NSSession -Feature "wl ssl lb cs gslb sslvpn rewrite responder"
    #endregion

    #region Configure NTP Servers
        # Add an NTP Server, using my own function
        Add-NSNTPServer -NSSession $NSSession -ServerIP "192.168.10.1"
        Add-NSNTPServer -NSSession $NSSession -ServerName "0.nl.pool.ntp.org"
        Write-Host "NTPServers: " -ForegroundColor Yellow -NoNewline
        Get-NSNTPServer -NSSession $NSSession | Select-Object servername, preferredntpserver | Format-List

        # Set NTP sync aan
        Enable-NSNTPSync -NSSession $NSSession
        # Retrieve the current NTP Sync setting
        Write-Host "NTPSync status: " -ForegroundColor Yellow -NoNewline
        Write-Host ((Get-NSNTPSync -NSSession $NSSession).state)
    #endregion

    #region Configure Users & Groups Administration
        # add a System User
        Add-NSSystemUser -NSSession $NSSession -UserName "system_user" -Password "password"
        # Retrieve system users
        Write-Host "System Users: " -ForegroundColor Yellow -NoNewline
        Get-NSSystemUser -NSSession $NSSession -UserName system_user | Select-Object username,priority,externalauth | Format-List

        # Bind a command policy to a system user
        Add-NSSystemUser -NSSession $NSSession -UserName "user_policy_binding" -Password "password" -ExternalAuth
        New-NSSystemUserSystemCmdPolicyBinding -NSSession $NSSession -UserName "user_policy_binding" -PolicyName "operator"
        New-NSSystemUserSystemCmdPolicyBinding -NSSession $NSSession -UserName "user_policy_binding" -PolicyName "superuser" -Priority 90
        # retrieve system user bindings
        Write-Host "User Bindings for system_user: " -ForegroundColor Yellow -NoNewline
        Get-NSSystemUserSystemCmdPolicyBinding -NSSession $NSSession -UserName "user_policy_binding" | Format-List

        # Add a System Group
        Add-NSSystemGroup -NSSession $NSSession -GroupName "system_group"
        # retrieve system groups
        Write-Host "System Groups: " -ForegroundColor Yellow -NoNewline
        Get-NSSystemGroup -NSSession $NSSession | Format-List

        # Bind a command policy to a system group
        Add-NSSystemGroup -NSSession $NSSession -GroupName "group_policy_binding"
        New-NSSystemGroupSystemCmdPolicyBinding -NSSession $NSSession -GroupName "group_policy_binding" -PolicyName "operator"
        # retrieve system group bindings
        Write-Host "Group Bindings for system_group: " -ForegroundColor Yellow -NoNewline
        Get-NSSystemGroupSystemCmdPolicyBinding -NSSession $NSSession -GroupName "group_policy_binding" | Format-List

        # Bind a system user to a system group
        New-NSSystemGroupSystemUserBinding -NSSession $NSSession -GroupName "system_group" -UserName "system_user"
        # retrieve system group bindings
        Write-Host "Group User Bindings for system_group: " -ForegroundColor Yellow -NoNewline
        Get-NSSystemGroupSystemUserBinding -NSSession $NSSession -GroupName "system_group" | Format-List
    #endregion

    #region Configure LDAP Authentication
        Add-NSAuthLDAPAction -NSSession $NSSession -LDAPActionName "ldap_auth_action" -LDAPServerIP "192.168.1.200" -LDAPBaseDN "DC=homelab,DC=local" `
         -LDAPBindDN "sa_ldapqueries@homelab.local" -LDAPBindDNPassword "password" -LDAPLoginName "administrator"
        Write-Host "LDAP Authentication Actions: " -ForegroundColor Yellow -NoNewline
        Get-NSAuthLDAPAction -NSSession $NSSession | Select-Object name, serverip, authentication, ldapbase, svrtype | Format-List

        Add-NSAuthLDAPPolicy -NSSession $NSSession -Name "ldap_auth_policy" -Action "ldap_auth_action" -RuleExpression "ns_false"
        Write-Host "LDAP Authentication Policies: " -ForegroundColor Yellow -NoNewline
        Get-NSAuthLDAPPolicy -NSSession $NSSession | Select-Object name, rule, reqaction | Format-List
    #endregion
