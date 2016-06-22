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

