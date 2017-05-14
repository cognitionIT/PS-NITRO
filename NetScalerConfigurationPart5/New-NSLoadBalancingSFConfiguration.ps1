<#
    .SYNOPSIS
        Create a new NetScaler Load Balancing configuration that works with StoreFront
    .DESCRIPTION
        Create a new NetScaler Load Balancing that works with StoreFront
        -Enable features
        -Create servers
        -Create services
        -Create LB monitors
        -Bind monitors to services
        -Create LB virtual server
        -Bind services to LB virtual server
        -Bind SSL certificate and key to LB virtual server 
    .PARAMETER NSAddress
        NetScaler Management IP address
    .PARAMETER NSName
        NetScaler DNS name or FQDN
    .PARAMETER NSUserName
        UserName to access the NetScaler appliance
    .PARAMETER NSPassword
        Password to access the NetScaler appliance
    .PARAMETER NSManagementProtocol
        Protocol to use to connect to the NetScaler appliance
    .PARAMETER StoreFrontServerName
        Name of the StoreFront servers to be load balanced
    .PARAMETER StoreFrontServerIPAddress
        IP address of the StoreFront servers to be load balanced
    .PARAMETER ServiceType
        Protocol in which data is exchanged with the StoreFront server service
    .PARAMETER ServicePort
        Port number of the StoreFront server service
    .PARAMETER StoreName
        Name of StoreFront Store
    .PARAMETER VirtualServerName
        Name of the virtual server
    .PARAMETER VirtualServerIPAddress
        IPv4 or IPv6 address to assign to the virtual server
        Usually a public IP address. User devices send connection requests to this IP address
    .PARAMETER CertKeyName
        Name of the certificate key pair
    .PARAMETER IPAddressFamily
        The IP address family (IPv4 or IPv6) to use in the case StoreFront IP addresses are not pass and need to be resolved
    .PARAMETER NetScalerConfigurationPSModuleLocation
        The full path to the location of the NetScaler Configuration PS module to be loaded
    .EXAMPLE 
        New-NSLoadBalancingSFConfiguration.ps1 -NSAddress "1.2.3.4" -NSUserName "nsroot" -NSPassword "nsroot" -NSManagementProtocol "HTTPS" -StoreFrontServerName "SF1","SF2" -StoreFrontServerIPAddress "2.3.4.5","2.3.4.6" -ServiceType "HTTPS" -ServicePort 443 -StoreName "StoreFrontStore" -VirtualServerName "storefront.mydomain.com" -VirtualServerIPAddress "23.45.67.89" -CertKeyName "storefront.mydomain.com" -NetScalerConfigurationPSModuleLocation "C:\NetScalerConfigurationPart3"

        Description
        -----------
        Creates new NetScaler Load Balancing configuration for StoreFront.
    .NOTES
        Version 1.0
        Copyright (c) Citrix Systems, Inc. All rights reserved.
#>


#Requires -Version 3

Param (
    #NS Connection
    [Parameter(Mandatory=$true,ParameterSetName='Address')] [string]$NSAddress,
    [Parameter(Mandatory=$true,ParameterSetName='Name')] [string]$NSName,
    [Parameter(Mandatory=$true)] [string]$NSUserName, 
    [Parameter(Mandatory=$true)] [string]$NSPassword,
    [Parameter(Mandatory=$true)] [ValidateSet("HTTP","HTTPS")][string]$NSManagementProtocol,
    
    #NS Server
    [Parameter(Mandatory=$false)] [string[]]$StoreFrontServerName,
    [Parameter(Mandatory=$false)] [string[]]$StoreFrontServerIPAddress,

    #NS Service
    [Parameter(Mandatory=$true)] [ValidateSet("HTTP","HTTPS")][string]$ServiceType,
    [Parameter(Mandatory=$true)] [ValidateRange(1,65535)] [int]$ServicePort,

    [Parameter(Mandatory=$true)] [string]$StoreName,
  
    #NS Gateway Virtual Server
    [Parameter(Mandatory=$true)] [string]$VirtualServerName,
    [Parameter(Mandatory=$true)] [string]$VirtualServerIPAddress,
    
    #NS SSL Certificate
    [Parameter(Mandatory=$true)] [string]$CertKeyName,

    [Parameter(Mandatory=$false)] [ValidateSet("IPv4","IPv6")][string]$IPAddressFamily="IPv4",

    [Parameter(Mandatory=$true)] [string]$NetScalerConfigurationPSModuleLocation
)


Import-Module $NetScalerConfigurationPSModuleLocation -ErrorAction Stop

if (-not $StoreFrontServerName -and -not $StoreFrontServerIPAddress) {
    throw "You must provide either the StoreFront server names or IP addresses (or both)"
} elseif (-not $StoreFrontServerIPAddress) {
    $StoreFrontServerIPAddress = @()
    foreach ($name in $StoreFrontServerName) {
        $dnsResponse = Resolve-DNSName -Name $name -Type $(if ($IPAddressFamily -eq "IPv4") { "A" } else { "AAAA" } )
        if ($dnsResponse) {
            $StoreFrontServerIPAddress += $dnsResponse[0].IPAddress
        } else {
            throw "An IP address for the StoreFront server '$name' was not returned by the DNS lookup"
        }
    }
}

if ($StoreFrontServerIPAddress.Count -le 1) {
    throw "You must include more than one server to be load balanced"
} elseif ($StoreFrontServerName.Count -eq 0) {
    $StoreFrontServerName = $StoreFrontServerIPAddress
} elseif ($StoreFrontServerName.Count -ne $StoreFrontServerIPAddress.Count) {
    throw "The number of servers names does not match the number of server IP addresses."
}

Write-Host "Validating IP Addresses"
foreach ($IPAddress in $StoreFrontServerIPAddress) {
    $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
    if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj)) {
        throw "'$IPAddress' is an invalid IP address"
    }
}

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

Set-NSMgmtProtocol -Protocol $NSManagementProtocol

Write-Host "$($MyInvocation.MyCommand): Connecting to NetScaler at '$nsEndpoint' as '$NSUserName'"
$nsSession = Connect-NSAppliance @nsConnectArgs

try {

    Write-Host "$($MyInvocation.MyCommand): Enabling NS features SSL,LB"
    Enable-NSFeature -NSSession $nsSession -Feature "SSL","LB"
    
    
    for ($i = 0;$i -lt $StoreFrontServerName.Count;$i++) {
        Write-Host "$($MyInvocation.MyCommand): Creating server '$($StoreFrontServerName[$i])'"
        Add-NSServer -NSSession $nsSession -Name $StoreFrontServerName[$i] -IPAddress $StoreFrontServerIPAddress[$i]
    }
    
    for ($i = 0;$i -lt $StoreFrontServerName.Count;$i++) {
        $serviceName = "$($StoreFrontServerName[$i])_Service"
        Write-Host "$($MyInvocation.MyCommand): Creating server service '$serviceName'"
        Add-NSService -NSSession $nsSession -Name $serviceName -ServerName $StoreFrontServerName[$i] -Type $ServiceType -Port $ServicePort `
                                             -InsertClientIPHeader -ClientIPHeader "X-Forwarded-For"
    }

    for ($i = 0;$i -lt $StoreFrontServerName.Count;$i++) {
        $monitorName = "$($StoreFrontServerName[$i])_Monitor"
        Write-Host "$($MyInvocation.MyCommand): Creating LB SF monitor"
        Add-NSLBSFMonitor -NSSession $nsSession -Name $monitorName -StoreFrontIPAddress $StoreFrontServerIPAddress[$i] -StoreName $StoreName
    }

    for ($i = 0;$i -lt $StoreFrontServerName.Count;$i++) {
        $serviceName = "$($StoreFrontServerName[$i])_Service"
        $monitorName = "$($StoreFrontServerName[$i])_Monitor"
        Write-Host "$($MyInvocation.MyCommand): Binding monitor to server service"
        New-NSServiceLBMonitorBinding -NSSession $nsSession -ServiceName $serviceName -MonitorName $monitorName
    }

    Write-Host "$($MyInvocation.MyCommand): Creating LB virtual server"
    Add-NSLBVServer -NSSession $nsSession -Name $VirtualServerName -IPAddress $VirtualServerIPAddress -ServiceType "SSL" -Port 443 -PersistenceType "SOURCEIP"

    for ($i = 0;$i -lt $StoreFrontServerName.Count;$i++) {
        $serviceName = "$($StoreFrontServerName[$i])_Service"
        Write-Host "$($MyInvocation.MyCommand): Binding service to LB virtual server"
        New-NSLBVServerServiceBinding -NSSession $nsSession -VirtualServerName $VirtualServerName -ServiceName $serviceName
    }

    Write-Host "$($MyInvocation.MyCommand): Binding SSL certificate to LB virtual server"
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
