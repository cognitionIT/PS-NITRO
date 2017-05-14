<#
    .SYNOPSIS
        Create a new NetScaler Gateway configuration that works with StoreFront
    .DESCRIPTION
        Create a new NetScaler Gateway configuration that works with StoreFront
        -Enable features
        -Create LDAP authentication action and policy
        -Create VPN virtual server
        -Bind LDAP policy to VPN virtual server
        -SF integration: Create session actions and policies, bind policies and STA servers to VPN virtual server
        -Bind SSL certificate and key to VPN virtual server 
    .PARAMETER NSAddress
        NetScaler Management IP address
    .PARAMETER NSName
        NetScaler DNS name or FQDN
    .PARAMETER NSUserName
        UserName to access the NetScaler appliance
    .PARAMETER NSPassword
        Password to access the NetScaler appliance
    .PARAMETER LDAPServerIP
        IP address assigned to the LDAP server
    .PARAMETER LDAPBaseDN
        Base (node) from which to start LDAP searches
    .PARAMETER LDAPBindDN
        Full distinguished name (DN) that is used to bind to the LDAP server
    .PARAMETER LDAPBindDNPassword,
        Password used to bind to the LDAP server
    .PARAMETER LDAPLoginName
        LDAP login name attribute. The NetScaler appliance uses the LDAP login name to query external LDAP servers or Active Directories
    .PARAMETER VirtualServerName
        Name of the virtual server
    .PARAMETER VirtualServerIPAddress
        IPv4 or IPv6 address to assign to the virtual server
        Usually a public IP address. User devices send connection requests to this IP address
    .PARAMETER StoreFrontServerURL
        URL including the name or IPAddress of the StoreFront Server
    .PARAMETER STAServerURL
        STA Server URL, usually the XenApp & XenDesktop Controllers
    .PARAMETER SingleSignOnDomain
        Single SignOn Domain Name, the same domain is used to autheticate to NetScaler Gateway and pass on to StoreFront
	.PARAMETER ReceiverForWebPath
        Path to the Receiver For Web Website
    .PARAMETER CertKeyName
        Name of the certificate key pair
    .PARAMETER NetScalerConfigurationPSModuleLocation
        The full path to the location of the NetScaler Configuration PS module to be loaded
    .EXAMPLE 
        New-NSGatewaySFConfiguration.ps1 -NSAddress "1.2.3.4" -LDAPServerIP "5.6.7.8" -LDAPBindDN "administrator@mydomain.com" -LDAPBindDNPassword "p4ssw0rd" -VirtualServerName "gateway.mydomain.com" -VirtualServerIPAddress "12.34.56.78" -StoreFrontServerURL "https://storefront.mydomain.com" -STAServerURL "https://controller1.mydomain.com","https://controller2.mydomain.com" -SingleSignOnDomain "mydomain.com" -ReceiverForWebPath "/Citrix/StoreWeb" -CertKeyName "gateway.mydomain.com" -NetScalerConfigurationPSModuleLocation "C:\NetScalerConfigurationPart4"

        Description
        -----------
        Creates new NetScaler Gateway configuration for StoreFront.
    .NOTES
        Version 1.0
        Copyright (c) Citrix Systems, Inc. All rights reserved.
#>

#Requires -Version 3

Param (
    #NS Connection
    [Parameter(Mandatory=$true,ParameterSetName='Address')] [string]$NSAddress,
    [Parameter(Mandatory=$true,ParameterSetName='Name')] [string]$NSName,
    [Parameter(Mandatory=$false)] [string]$NSUserName="nsroot", 
    [Parameter(Mandatory=$false)] [string]$NSPassword="nsroot",
    
    #NS Authentication
    [Parameter(Mandatory=$true)] [string]$LDAPServerIP,
    [Parameter(Mandatory=$false)] [string]$LDAPBaseDN,
    [Parameter(Mandatory=$true)] [string]$LDAPBindDN,
    [Parameter(Mandatory=$true)] [string]$LDAPBindDNPassword,
    [Parameter(Mandatory=$false)] [string]$LDAPLoginName="sAMAccountName",
  
    #NS Gateway Virtual Server
    [Parameter(Mandatory=$true)] [string]$VirtualServerName,
    [Parameter(Mandatory=$true)] [string]$VirtualServerIPAddress,
    
    #NS Gateway with StoreFront
    [Parameter(Mandatory=$true)] [string]$StoreFrontServerURL,
    [Parameter(Mandatory=$true)] [string[]]$STAServerURL,
    [Parameter(Mandatory=$true)] [ValidatePattern("(?=^.{4,255}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}$)")] [string]$SingleSignOnDomain,
    [Parameter(Mandatory=$true)] [string]$ReceiverForWebPath,

    #NS SSL Certificate
    [Parameter(Mandatory=$true)] [string]$CertKeyName,

    [Parameter(Mandatory=$true)] [string]$NetScalerConfigurationPSModuleLocation
)


Import-Module $NetScalerConfigurationPSModuleLocation -ErrorAction Stop

$nsConnectArgs = @{
    NSUserName = $NSUserName
    NSPassword = $NSPassword
    Verbose = $true
}
if ($PSCmdlet.ParameterSetName -eq 'Address') {
    $nsEndpoint = $NSAddress
    $nsConnectArgs.Add("NSAddress",$NSAddress)
} elseif ($PSCmdlet.ParameterSetName -eq 'Name') {
    $nsEndpoint = $NSName
    $nsConnectArgs.Add("NSName",$NSName)
}

if ([string]::IsNullOrEmpty($LDAPBaseDN)) {
    $domainArray = $SingleSignOnDomain -split '\.'
    $LDAPBaseDN = "dc=" + $($domainArray -join ',dc=')
}

Write-Host "$($MyInvocation.MyCommand): Connecting to NetScaler at '$nsEndpoint' as '$NSUserName'"
$nsSession = Connect-NSAppliance @nsConnectArgs

try {
    Write-Host "$($MyInvocation.MyCommand): Enabling NS features SSL,SSLVPN,AAA"
    Enable-NSFeature -NSSession $nsSession -Feature "SSL","SSLVPN","AAA"
    
    Write-Host "$($MyInvocation.MyCommand): Creating LDAP authentication action"
    Add-NSAuthLDAPAction -NSSession $nsSession -LDAPActionName $LDAPServerIP -LDAPServerIP $LDAPServerIP -LDAPBaseDN $LDAPBaseDN -LDAPBindDN $LDAPBindDN `
                                                -LDAPBindDNPassword $LDAPBindDNPassword -LDAPLoginName $LDAPLoginName

    Write-Host "$($MyInvocation.MyCommand): Creating LDAP authentication policy"
    Add-NSAuthLDAPPolicy -NSSession $nsSession -LDAPActionName $LDAPServerIP -LDAPPolicyName $LDAPServerIP -LDAPRuleExpression "ns_true"

    Write-Host "$($MyInvocation.MyCommand): Creating VPN virtual server"
    Add-NSVPNVServer -NSSession $nsSession -Name $VirtualServerName -IPAddress $VirtualServerIPAddress -Port 443

    Write-Host "$($MyInvocation.MyCommand): Binding LDAP authentication policy to VPN virtual server"
    New-NSVPNVServerAuthLDAPPolicyBinding -NSSession $nsSession -VirtualServerName $VirtualServerName -LDAPPolicyName $LDAPServerIP

    Write-Host "$($MyInvocation.MyCommand): Setting up Gateway's StoreFront store integration"
    Set-NSSFStore -NSSession $nsSession -VirtualServerName $VirtualServerName -VirtualServerIPAddress $VirtualServerIPAddress -StoreFrontServerURL $StoreFrontServerURL `
                                         -STAServerURL $STAServerURL -SingleSignOnDomain $SingleSignOnDomain -ReceiverForWebPath $ReceiverForWebPath
    
    Write-Host "$($MyInvocation.MyCommand): Binding SSL certificate to VPN virtual server"
    New-NSSSLVServerCertKeyBinding -NSSession $nsSession -CertKeyName $CertKeyName -VirtualServerName $VirtualServerName

    Write-Host "$($MyInvocation.MyCommand): Saving NS configuration"
    Save-NSConfig -NSSession $nsSession
}
finally {
    if ($nsSession) {
        Write-Host "$($MyInvocation.MyCommand): Disconnecting from NetScaler at '$nsEndpoint'"
        Disconnect-NSAppliance -NSSession $nsSession
    }
}
