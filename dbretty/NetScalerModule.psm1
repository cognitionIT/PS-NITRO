function Login-NetScaler {
<# 
.SYNOPSIS 
 Logs into a Citrix NetScaler.
.DESCRIPTION 
 Logs into a NetScaler ADC and creates a global variable called $NSSession to be used to invoke NITRO Commands.
.PARAMETER NSIP 
 Citrix NetScaler NSIP.
.PARAMETER UserName 
 UserName to be used for login.
.PARAMETER Password
 The Password to be used for Login 
.NOTES 
 Name: Login-NetScaler
 Author: David Brett - Citrix CTP
 Date Created: 15/03/2017
.CHANGE LOG
 David Brett - 15/03/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $False,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP,
 [Parameter(
 Mandatory = $False,
 Position = 1,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$UserName,
 [Parameter(
 Mandatory = $False,
 Position = 2,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Password
 )

 #Check to see if parameters were passed in, if not then prompt the user for them
 if ($NSIP -eq "") {$NSIP = read-host "Enter NetScaler IP"}
 if ($UserName -eq "") {$UserName = read-host "Enter NetScaler User Name"}
 if ($Password -eq "") {
 $SecurePassword = read-host "Enter NetScaler Password" -AsSecureString
 $BasePassword = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
 $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BasePassword)
 }

 #Validate That the IP Address is valid
 Validate-IP $NSIP

 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "login"=@{
 "username"=$UserName;
 "password"=$Password
 }
 }

 #Connect to NetScaler
 Invoke-RestMethod -uri "$NSIP/nitro/v1/config/login" -body $PayLoad -SessionVariable saveSession -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.login+json"} -Method POST

 #Build Global NetScaler Session Variable
 $Global:nsSession = New-Object -TypeName PSObject
 $nsSession | Add-Member -NotePropertyName Endpoint -NotePropertyValue $NSIP -TypeName String
 $nsSession | Add-Member -NotePropertyName WebSession -NotePropertyValue $saveSession -TypeName Microsoft.PowerShell.Commands.WebRequestSession

 #Return NetScaler Session
 return $nsSession
}

function Logout-NetScaler {
<# 
.SYNOPSIS 
 Logs out of a Citrix NetScaler.
.DESCRIPTION 
 Logs out of a Citrix NetScaler and clears the NSSession Global Variable.
.PARAMETER NSIP 
 Citrix NetScaler NSIP. 
.NOTES 
 Name: Logout-NetScaler
 Author: David Brett - Citrix CTP
 Date Created: 15/03/2017 
.CHANGE LOG
 David Brett - 15/03/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $False,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP
 )

 #Validate That the IP Address is valid
 Validate-IP $NSIP

 #Check to see if a valid NSSession is active. If not then quit the function
 if ($NSSession -eq "") {
 write-host -ForegroundColor Red "No valid NetScaler session found, quitting"
 break
 }

 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "logout"=@{
 }
 }

 #Logout of the NetScaler
 Invoke-RestMethod -uri "$NSIP/nitro/v1/config/logout" -body $PayLoad -WebSession $NSSession.WebSession -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.logout+json"} -Method POST

 #Clear the Global Variable for the NetScaler Session
 Remove-Variable -name nsSession -Scope global -force
}

function Validate-IP {
<# 
.SYNOPSIS 
 Validate a passed in IP Address.
.DESCRIPTION 
 Validate a passed in IP Address.
.PARAMETER IPAddress 
 IP Address to be validated. 
.NOTES 
 Name: Validate-IP
 Author: David Brett - Citrix CTP
 Date Created: 15/03/2017 
.CHANGE LOG
 David Brett - 15/03/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $False,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$IPAddress
 )

 if ([BOOL]($IPAddress -as [IPADDRESS])){
 return $True 
 } else {
 write-Host -ForegroundColor Red "$IPAddress is an invalid address - quitting"
 break
 }
}

function Add-NetScalerNTP {
<# 
.SYNOPSIS 
 Add a NTP Server to a NetScaler.
.DESCRIPTION 
 Add a NTP Server to a NetScaler.
.PARAMETER NtpIP 
 NTP Server IP Address 
.PARAMETER NSIP 
 NetScaler IP Address 
.NOTES 
 Name: Add-NetScalerNTP
 Author: David Brett - Citrix CTP
 Date Created: 21/04/2017 
.CHANGE LOG
 David Brett - 21/04/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $True,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NtpIP,
 [Parameter(
 Mandatory = $True,
 Position = 1,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP
 )

 #Check if there is a valid NetScaler session active
 if ($nssession -eq $null) {
 write-host -ForegroundColor Red "NetScaler Login is required to continue, please use Login-NetScaler, quitting"
 break
 }

 #Check if the vServer exists and is already disabled
 $Url = "$NSIP/nitro/v1/config/ntpserver/$NtpIP"
 $Method = "GET"
 $ContentType = "application/json"

 try {
 $NtpIPStatus = Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Method $Method
 $NTPStatus = "Good"
 } catch {
 $ErrException = $_.Exception.Response.StatusCode.value__
 if ($ErrException -eq 404) {
 $NtpStatus = "Bad"
 cls
 write-host -ForegroundColor Red "NTP Server is not found, adding NTP Server"
 }
 }

 if ($NtpStatus -eq "Bad" ) {
 #Set up the NetScaler Url for NITRO
 $Url = "$NSIP/nitro/v1/config/ntpserver"

 #Set the HTTP Method
 $Method = "POST"

 #Set the Request Header for Content Type
 $ContentType = "application/json"
 
 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "ntpserver"=@{
 "serverip"=$NtpIP
 }
 }

 #Execute the NetScaler Nitro Command and catch the output. If error then break the function
 Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Body $Payload -Method $Method
 cls
 write-host -ForegroundColor Green "$NtpIP has been added"
 } else {
 write-host -ForegroundColor Green "$NtpIP already exists"
 }

}

function Add-NetScalerLdapServer {
<# 
.SYNOPSIS 
 Adds a LDAP Authentication Server to a NetScaler.
.DESCRIPTION 
 Adds a LDAP Authentication Server to a NetScaler.
.PARAMETER NSIP 
 NetScaler IP Address 
.PARAMETER Name
 NetScaler LDAP Server Name
.PARAMETER ServerIP
 LDAP Server IP
.PARAMETER SecurityType
 LDAP Security Type
.PARAMETER Port
 LDAP Server Port
.PARAMETER ServerType
 LDAP Server Type
.PARAMETER Timeout
 LDAP Server Timeout
.PARAMETER BaseDN
 LDAP Base DN
.PARAMETER BindDN
 LDAP Bind DN
.PARAMETER AdminPass
 LDAP Admin Password
.PARAMETER LoginNameAttr
 LDAP Login Name Attribute
.PARAMETER GroupAttr
 LDAP Group Attribute
.PARAMETER SubAttribute
 LDAP Sub Login Attribute
.PARAMETER SingleSignOnAttr
 LDAP Single Sign On Attribute 
.NOTES 
 Name: Add-NetScalerLdapServer
 Author: David Brett - Citrix CTP
 Date Created: 21/04/2017 
.CHANGE LOG
 David Brett - 21/04/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $True,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP,
 [Parameter(
 Mandatory = $True,
 Position = 1,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Name,
 [Parameter(
 Mandatory = $True,
 Position = 2,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$ServerIP,
 [Parameter(
 Mandatory = $True,
 Position = 3,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$SecurityType,
 [Parameter(
 Mandatory = $True,
 Position = 4,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Port,
 [Parameter(
 Mandatory = $True,
 Position = 5,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$ServerType,
 [Parameter(
 Mandatory = $True,
 Position = 6,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Timeout,
 [Parameter(
 Mandatory = $True,
 Position = 7,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$BaseDN,
 [Parameter(
 Mandatory = $True,
 Position = 8,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$BindDN,
 [Parameter(
 Mandatory = $True,
 Position = 9,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$AdminPass,
 [Parameter(
 Mandatory = $True,
 Position = 10,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$LoginNameAttr,
 [Parameter(
 Mandatory = $True,
 Position = 11,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$GroupAttr,
 [Parameter(
 Mandatory = $True,
 Position = 12,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$SubAttr,
 [Parameter(
 Mandatory = $True,
 Position = 13,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$SingleSignOnAttr
 )

 #Check if there is a valid NetScaler session active
 if ($nssession -eq $null) {
 write-host -ForegroundColor Red "NetScaler Login is required to continue, please use Login-NetScaler, quitting"
 break
 }

 #Check if the LDAP Server exists
 $Url = "$NSIP/nitro/v1/config/authenticationldapaction/$Name"
 $Method = "GET"
 $ContentType = "application/json"

 try {
 $LDAPStatus = Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Method $Method
 $LDAPStatus = "Good"
 } catch {
 $ErrException = $_.Exception.Response.StatusCode.value__
 if ($ErrException -eq 404) {
 $LDAPStatus = "Bad"
 cls
 write-host -ForegroundColor Red "LDAP Server is not found, adding LDAP Server"
 }
 }

 if ($LDAPStatus -eq "Bad" ) {
 #Set up the NetScaler Url for NITRO
 $Url = "$NSIP/nitro/v1/config/authenticationldapaction"

 #Set the HTTP Method
 $Method = "POST"

 #Set the Request Header for Content Type
 $ContentType = "application/json"
 
 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "authenticationldapaction"=@{
 "name"=$Name;
 "serverip"=$ServerIP;
 "serverport"=$Port;
 "authtimeout"=$Timeout;
 "ldapbase"=$BaseDN;
 "ldapbinddn"=$BindDN;
 "ldapbinddnpassword"=$AdminPass;
 "ldaploginname"=$LoginNameAttr;
 "groupattrname"=$GroupAttr;
 "subattributename"=$SubAttribute;
 "sectype"=$SecurityType;
 "svrtype"=$ServerType;
 "ssonameattribute"=$SingleSignOnAttr
 }
 }

 #Execute the NetScaler Nitro Command and catch the output. If error then break the function
 Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Body $Payload -Method $Method
 cls
 write-host -ForegroundColor Green "LDAP Server has been added"
 } else {
 write-host -ForegroundColor Green "LDAP Server already exists"
 }

}

function Add-NetScalerLdapPolicy {
<# 
.SYNOPSIS 
 Adds a LDAP Authentication Policy to a NetScaler.
.DESCRIPTION 
 Adds a LDAP Authentication Policy to a NetScaler.
.PARAMETER NSIP 
 NetScaler IP Address 
.PARAMETER Name
 NetScaler LDAP Server Name
.PARAMETER Rule
 LDAP Server IP
.PARAMETER ReqAction
 LDAP Security Type
.NOTES 
 Name: Add-NetScalerLdapPolicy
 Author: David Brett - Citrix CTP
 Date Created: 21/04/2017 
.CHANGE LOG
 David Brett - 21/04/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $True,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP,
 [Parameter(
 Mandatory = $True,
 Position = 1,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Name,
 [Parameter(
 Mandatory = $True,
 Position = 2,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Rule,
 [Parameter(
 Mandatory = $True,
 Position = 3,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$ReqAction
 )

 #Check if there is a valid NetScaler session active
 if ($nssession -eq $null) {
 write-host -ForegroundColor Red "NetScaler Login is required to continue, please use Login-NetScaler, quitting"
 break
 }

 #Check if the LDAP Policy exists
 $Url = "$NSIP/nitro/v1/config/authenticationldappolicy/$Name"
 $Method = "GET"
 $ContentType = "application/json"

 try {
 $LDAPStatus = Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Method $Method
 $LDAPStatus = "Good"
 } catch {
 $ErrException = $_.Exception.Response.StatusCode.value__
 if ($ErrException -eq 404) {
 $LDAPStatus = "Bad"
 cls
 write-host -ForegroundColor Red "LDAP Policy is not found, adding LDAP Policy"
 }
 }

 if ($LDAPStatus -eq "Bad" ) {
 #Set up the NetScaler Url for NITRO
 $Url = "$NSIP/nitro/v1/config/authenticationldappolicy"

 #Set the HTTP Method
 $Method = "POST"

 #Set the Request Header for Content Type
 $ContentType = "application/json"
 
 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "authenticationldappolicy"=@{
 "name"=$Name;
 "rule"=$Rule;
 "reqaction"=$ReqAction
 }
 }

 #Execute the NetScaler Nitro Command and catch the output. If error then break the function
 Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Body $Payload -Method $Method
 cls
 write-host -ForegroundColor Green "LDAP Policy has been added"
 } else {
 write-host -ForegroundColor Green "LDAP Policy already exists"
 }

}


function Add-NetScalerSessionAction {
<# 
.SYNOPSIS 
 Adds a NetScaler Gateway Session Action to a NetScaler.
.DESCRIPTION 
 Adds a NetScaler Gateway Session Action to a NetScaler.
.PARAMETER NSIP 
 NetScaler IP Address 
.PARAMETER Name
 NetScaler Session Action Server Name
.PARAMETER DefaultAuth
 Default Authorisation
.PARAMETER ICAProxy
 ICA Proxy
.PARAMETER WebInterfaceAddress
 Web Interface Address
.PARAMETER SSODomain
 Single Sign On Domain
.NOTES 
 Name: Add-NetScalerSessionAction
 Author: David Brett - Citrix CTP
 Date Created: 21/04/2017 
.CHANGE LOG
 David Brett - 21/04/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $True,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP,
 [Parameter(
 Mandatory = $True,
 Position = 1,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Name,
 [Parameter(
 Mandatory = $True,
 Position = 2,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$DefaultAuth,
 [Parameter(
 Mandatory = $True,
 Position = 3,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$ICAProxy,
 [Parameter(
 Mandatory = $True,
 Position = 4,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$WebInterfaceAddress,
 [Parameter(
 Mandatory = $True,
 Position = 5,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$SSODomain
 )

 #Check if there is a valid NetScaler session active
 if ($nssession -eq $null) {
 write-host -ForegroundColor Red "NetScaler Login is required to continue, please use Login-NetScaler, quitting"
 break
 }

 #Check if the LDAP Policy exists
 $Url = "$NSIP/nitro/v1/config/vpnsessionaction/$Name"
 $Method = "GET"
 $ContentType = "application/json"

 try {
 $SessionStatus = Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Method $Method
 $SessionStatus = "Good"
 } catch {
 $ErrException = $_.Exception.Response.StatusCode.value__
 if ($ErrException -eq 404) {
 $SessionStatus = "Bad"
 cls
 write-host -ForegroundColor Red "NetScaler Session Action is not found, adding LDAP Policy"
 }
 }

 if ($SessionStatus -eq "Bad" ) {
 #Set up the NetScaler Url for NITRO
 $Url = "$NSIP/nitro/v1/config/vpnsessionaction"

 #Set the HTTP Method
 $Method = "POST"

 #Set the Request Header for Content Type
 $ContentType = "application/json"
 
 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "vpnsessionaction"=@{
 "name"=$Name;
 "defaultauthorizationaction"=$DefaultAuth;
 "icaproxy"=$ICAProxy;
 "wihome"=$WebInterfaceAddress;
 "ntdomain"=$SSODomain
 }
 }

 #Execute the NetScaler Nitro Command and catch the output. If error then break the function
 Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Body $Payload -Method $Method
 cls
 write-host -ForegroundColor Green "NetScaler Session Policy has been added"
 } else {
 write-host -ForegroundColor Green "NetScaler Session Policy already exists"
 }

}


function Add-NetScalerSessionPolicy {
<# 
.SYNOPSIS 
 Adds a NetScaler Session Policy to a NetScaler.
.DESCRIPTION 
 Adds a NetScaler Session Policy to a NetScaler.
.PARAMETER NSIP 
 NetScaler IP Address 
.PARAMETER Name
 NetScaler Session Policy Name
.PARAMETER Rule
 NetScaler Session Policy Rule
.PARAMETER Action
 NetScaler Session Policy Action
.NOTES 
 Name: Add-NetScalerSessionPolicy
 Author: David Brett - Citrix CTP
 Date Created: 21/04/2017 
.CHANGE LOG
 David Brett - 21/04/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $True,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP,
 [Parameter(
 Mandatory = $True,
 Position = 1,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Name,
 [Parameter(
 Mandatory = $True,
 Position = 2,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Rule,
 [Parameter(
 Mandatory = $True,
 Position = 3,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Action
 )

 #Check if there is a valid NetScaler session active
 if ($nssession -eq $null) {
 write-host -ForegroundColor Red "NetScaler Login is required to continue, please use Login-NetScaler, quitting"
 break
 }

 #Check if the LDAP Policy exists
 $Url = "$NSIP/nitro/v1/config/vpnsessionpolicy/$Name"
 $Method = "GET"
 $ContentType = "application/json"

 try {
 $SessionStatus = Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Method $Method
 $SessionStatus = "Good"
 } catch {
 $ErrException = $_.Exception.Response.StatusCode.value__
 if ($ErrException -eq 404) {
 $SessionStatus = "Bad"
 cls
 write-host -ForegroundColor Red "Session Policy is not found, adding LDAP Policy"
 }
 }

 if ($SessionStatus -eq "Bad" ) {
 #Set up the NetScaler Url for NITRO
 $Url = "$NSIP/nitro/v1/config/vpnsessionpolicy"

 #Set the HTTP Method
 $Method = "POST"

 #Set the Request Header for Content Type
 $ContentType = "application/json"
 
 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "vpnsessionpolicy"=@{
 "name"=$Name;
 "rule"=$Rule;
 "action"=$Action
 }
 }

 #Execute the NetScaler Nitro Command and catch the output. If error then break the function
 Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Body $Payload -Method $Method
 cls
 write-host -ForegroundColor Green "Session Policy has been added"
 } else {
 write-host -ForegroundColor Green "Session Policy already exists"
 }

}

function Add-NetScalerGateway {
<# 
.SYNOPSIS 
 Adds a NetScaler Gateway to a NetScaler.
.DESCRIPTION 
 Adds a NetScaler Gateway to a NetScaler.
.PARAMETER NSIP 
 NetScaler IP Address 
.PARAMETER Name
 NetScaler Gateway Server Name
.PARAMETER ServiceType
 Service Type
.PARAMETER IPv46
 IP Address of the Gateway
.PARAMETER ICAOnly
 ICA Only Gateway
.NOTES 
 Name: Add-NetScalerGateway
 Author: David Brett - Citrix CTP
 Date Created: 21/04/2017 
.CHANGE LOG
 David Brett - 21/04/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $True,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP,
 [Parameter(
 Mandatory = $True,
 Position = 1,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Name,
 [Parameter(
 Mandatory = $True,
 Position = 2,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$ServiceType
 )

 #Check if there is a valid NetScaler session active
 if ($nssession -eq $null) {
 write-host -ForegroundColor Red "NetScaler Login is required to continue, please use Login-NetScaler, quitting"
 break
 }

 #Check if the LDAP Policy exists
 $Url = "$NSIP/nitro/v1/config/vpnvserver/$Name"
 $Method = "GET"
 $ContentType = "application/json"

 try {
 $GatewayStatus = Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Method $Method
 $GatewayStatus = "Good"
 } catch {
 $ErrException = $_.Exception.Response.StatusCode.value__
 if ($ErrException -eq 404) {
 $GatewayStatus = "Bad"
 cls
 write-host -ForegroundColor Red "NetScaler Gateway is not found, adding NetScaler Gateway"
 }
 }

 if ($GatewayStatus -eq "Bad" ) {
 #Set up the NetScaler Url for NITRO
 $Url = "$NSIP/nitro/v1/config/vpnvserver"

 #Set the HTTP Method
 $Method = "POST"

 #Set the Request Header for Content Type
 $ContentType = "application/json"
 
 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "vpnvserver"=@{
 "name"=$Name;
 "servicetype"=$ServiceType
 }
 }

 #Execute the NetScaler Nitro Command and catch the output. If error then break the function
 Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Body $Payload -Method $Method
 cls
 write-host -ForegroundColor Green "NetScaler Gateway has been added"
 } else {
 write-host -ForegroundColor Green "NetScaler Gateway already exists"
 }

}

function Add-ContentSwitch {
<# 
.SYNOPSIS 
 Adds a Content Switch to a NetScaler.
.DESCRIPTION 
 Adds a Content Switch to a NetScaler.
.PARAMETER NSIP 
 NetScaler IP Address 
.PARAMETER Name
 Content Switch Name
.PARAMETER ServiceType
 Service Type
.PARAMETER IPv46
 IP Address of the Gateway
.PARAMETER Port
 Port
.NOTES 
 Name: Add-ContentSwitch
 Author: David Brett - Citrix CTP
 Date Created: 21/04/2017 
.CHANGE LOG
 David Brett - 21/04/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $True,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP,
 [Parameter(
 Mandatory = $True,
 Position = 1,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Name,
 [Parameter(
 Mandatory = $True,
 Position = 2,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$ServiceType,
 [Parameter(
 Mandatory = $True,
 Position = 3,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$IPv46,
 [Parameter(
 Mandatory = $True,
 Position = 4,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Port
 )

 #Check if there is a valid NetScaler session active
 if ($nssession -eq $null) {
 write-host -ForegroundColor Red "NetScaler Login is required to continue, please use Login-NetScaler, quitting"
 break
 }

 #Check if the LDAP Policy exists
 $Url = "$NSIP/nitro/v1/config/csvserver/$Name"
 $Method = "GET"
 $ContentType = "application/json"

 try {
 $CSStatus = Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Method $Method
 $CSStatus = "Good"
 } catch {
 $ErrException = $_.Exception.Response.StatusCode.value__
 if ($ErrException -eq 404) {
 $CSStatus = "Bad"
 cls
 write-host -ForegroundColor Red "Content Switch is not found, adding Content Switch"
 }
 }

 if ($CSStatus -eq "Bad" ) {
 #Set up the NetScaler Url for NITRO
 $Url = "$NSIP/nitro/v1/config/csvserver"

 #Set the HTTP Method
 $Method = "POST"

 #Set the Request Header for Content Type
 $ContentType = "application/json"
 
 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "csvserver"=@{
 "name"=$Name;
 "servicetype"=$ServiceType;
 "ipv46"=$IPv46;
 "Port"=$Port
 }
 }

 #Execute the NetScaler Nitro Command and catch the output. If error then break the function
 Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Body $Payload -Method $Method
 cls
 write-host -ForegroundColor Green "Content Switch has been added"
 } else {
 write-host -ForegroundColor Green "Content Switch already exists"
 }

}

function Bind-ContentSwitchDefaultvServer {
<# 
.SYNOPSIS 
 Binds a default VPN vServer to the Content Switch.
.DESCRIPTION 
 Binds a default VPN vServer to the Content Switch.
.PARAMETER NSIP 
 NetScaler IP Address 
.PARAMETER Name
 Content Switch Name
.PARAMETER vServer
 vServer Name
.NOTES 
 Name: Add-ContentSwitchDefaultvServer
 Author: David Brett - Citrix CTP
 Date Created: 21/04/2017 
.CHANGE LOG
 David Brett - 21/04/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $True,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP,
 [Parameter(
 Mandatory = $True,
 Position = 1,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Name,
 [Parameter(
 Mandatory = $True,
 Position = 2,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$vServer
 )

 #Check if there is a valid NetScaler session active
 if ($nssession -eq $null) {
 write-host -ForegroundColor Red "NetScaler Login is required to continue, please use Login-NetScaler, quitting"
 break
 }


 #Set up the NetScaler Url for NITRO
 $Url = "$NSIP/nitro/v1/config/csvserver_vpnvserver_binding"

 #Set the HTTP Method
 $Method = "POST"

 #Set the Request Header for Content Type
 $ContentType = "application/json"
 
 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "csvserver_vpnvserver_binding"=@{
 "name"=$Name;
 "vserver"=$vServer
 }
 }

 #Execute the NetScaler Nitro Command and catch the output. If error then break the function
 Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Body $Payload -Method $Method
 cls
 write-host -ForegroundColor Green "Content Switch Binding has been added"

}

function Bind-CertificateCS {
<# 
.SYNOPSIS 
 Binds a Certificate to the Content Switch.
.DESCRIPTION 
 Binds a Certificate to the Content Switch.
.PARAMETER NSIP 
 NetScaler IP Address 
.PARAMETER Name
 Content Switch Name
.PARAMETER CertName
 Certificate Name
.NOTES 
 Name: Bind-CertificateCS
 Author: David Brett - Citrix CTP
 Date Created: 21/04/2017 
.CHANGE LOG
 David Brett - 21/04/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $True,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP,
 [Parameter(
 Mandatory = $True,
 Position = 1,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Name,
 [Parameter(
 Mandatory = $True,
 Position = 2,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$CertName
 )

 #Check if there is a valid NetScaler session active
 if ($nssession -eq $null) {
 write-host -ForegroundColor Red "NetScaler Login is required to continue, please use Login-NetScaler, quitting"
 break
 }


 #Set up the NetScaler Url for NITRO
 $Url = "$NSIP/nitro/v1/config/sslvserver_sslcertkey_binding"

 #Set the HTTP Method
 $Method = "POST"

 #Set the Request Header for Content Type
 $ContentType = "application/json"
 
 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "sslvserver_sslcertkey_binding"=@{
 "vservername"=$Name;
 "certkeyname"=$CertName
 }
 }

 #Execute the NetScaler Nitro Command and catch the output. If error then break the function
 Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Body $Payload -Method $Method
 cls
 write-host -ForegroundColor Green "Content Switch Binding has been added"

}

function Bind-CertificateGW {
<# 
.SYNOPSIS 
 Binds a Certificate to the NetScaler Gateway.
.DESCRIPTION 
 Binds a Certificate to the NetScaler Gateway.
.PARAMETER NSIP 
 NetScaler IP Address 
.PARAMETER Name
 NetScaler Gateway Name
.PARAMETER CertName
 Certificate Name
.NOTES 
 Name: Bind-CertificateCS
 Author: David Brett - Citrix CTP
 Date Created: 21/04/2017 
.CHANGE LOG
 David Brett - 21/04/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $True,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP,
 [Parameter(
 Mandatory = $True,
 Position = 1,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Name,
 [Parameter(
 Mandatory = $True,
 Position = 2,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$CertName
 )

 #Check if there is a valid NetScaler session active
 if ($nssession -eq $null) {
 write-host -ForegroundColor Red "NetScaler Login is required to continue, please use Login-NetScaler, quitting"
 break
 }


 #Set up the NetScaler Url for NITRO
 $Url = "$NSIP/nitro/v1/config/sslvserver_sslcertkey_binding"

 #Set the HTTP Method
 $Method = "POST"

 #Set the Request Header for Content Type
 $ContentType = "application/json"
 
 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "sslvserver_sslcertkey_binding"=@{
 "vservername"=$Name;
 "certkeyname"=$CertName
 }
 }

 #Execute the NetScaler Nitro Command and catch the output. If error then break the function
 Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Body $Payload -Method $Method
 cls
 write-host -ForegroundColor Green "Content Switch Binding has been added"

}

function Bind-GatewayLDAP {
<# 
.SYNOPSIS 
 Binds a LDAP Auth Policy to the NetScaler Gateway.
.DESCRIPTION 
 Binds a LDAP Auth Policy to the NetScaler Gateway.
.PARAMETER NSIP 
 NetScaler IP Address 
.PARAMETER Name
 NetScaler Gateway Name
.PARAMETER PolicyName
 LDAP Policy Name
.NOTES 
 Name: Bind-GatewayLDAP
 Author: David Brett - Citrix CTP
 Date Created: 21/04/2017 
.CHANGE LOG
 David Brett - 21/04/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $True,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP,
 [Parameter(
 Mandatory = $True,
 Position = 1,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Name,
 [Parameter(
 Mandatory = $True,
 Position = 2,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$PolicyName
 )

 #Check if there is a valid NetScaler session active
 if ($nssession -eq $null) {
 write-host -ForegroundColor Red "NetScaler Login is required to continue, please use Login-NetScaler, quitting"
 break
 }


 #Set up the NetScaler Url for NITRO
 $Url = "$NSIP/nitro/v1/config/vpnvserver_authenticationldappolicy_binding"

 #Set the HTTP Method
 $Method = "POST"

 #Set the Request Header for Content Type
 $ContentType = "application/json"
 
 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "vpnvserver_authenticationldappolicy_binding"=@{
 "name"=$Name;
 "policy"=$PolicyName
 }
 }

 #Execute the NetScaler Nitro Command and catch the output. If error then break the function
 Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Body $Payload -Method $Method
 cls
 write-host -ForegroundColor Green "LDAP Policy Binding Complete"

}

function Bind-GatewaySession {
<# 
.SYNOPSIS 
 Binds a Session Policy to the NetScaler Gateway.
.DESCRIPTION 
 Binds a Session Policy to the NetScaler Gateway.
.PARAMETER NSIP 
 NetScaler IP Address 
.PARAMETER Name
 NetScaler Gateway Name
.PARAMETER PolicyName
 Session Policy Name
.NOTES 
 Name: Bind-GatewaySession
 Author: David Brett - Citrix CTP
 Date Created: 21/04/2017 
.CHANGE LOG
 David Brett - 21/04/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $True,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP,
 [Parameter(
 Mandatory = $True,
 Position = 1,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Name,
 [Parameter(
 Mandatory = $True,
 Position = 2,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$PolicyName
 )

 #Check if there is a valid NetScaler session active
 if ($nssession -eq $null) {
 write-host -ForegroundColor Red "NetScaler Login is required to continue, please use Login-NetScaler, quitting"
 break
 }


 #Set up the NetScaler Url for NITRO
 $Url = "$NSIP/nitro/v1/config/vpnvserver_vpnsessionpolicy_binding"

 #Set the HTTP Method
 $Method = "POST"

 #Set the Request Header for Content Type
 $ContentType = "application/json"
 
 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "vpnvserver_vpnsessionpolicy_binding"=@{
 "name"=$Name;
 "policy"=$PolicyName
 }
 }

 #Execute the NetScaler Nitro Command and catch the output. If error then break the function
 Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Body $Payload -Method $Method
 cls
 write-host -ForegroundColor Green "LDAP Policy Binding Complete"

}

function Bind-GatewaySTA {
<# 
.SYNOPSIS 
 Binds a STA to the NetScaler Gateway.
.DESCRIPTION 
 Binds a STA to the NetScaler Gateway.
.PARAMETER NSIP 
 NetScaler IP Address 
.PARAMETER Name
 NetScaler Gateway Name
.PARAMETER StaUrl
 STA Url
.NOTES 
 Name: Bind-GatewaySTA
 Author: David Brett - Citrix CTP
 Date Created: 21/04/2017 
.CHANGE LOG
 David Brett - 21/04/2017 - Initial Script Creation 
.LINK 
 http://bretty.me.uk
#> 

 [cmdletbinding(
 DefaultParameterSetName = '',
 ConfirmImpact = 'low'
 )]

 Param (
 [Parameter(
 Mandatory = $True,
 Position = 0,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$NSIP,
 [Parameter(
 Mandatory = $True,
 Position = 1,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$Name,
 [Parameter(
 Mandatory = $True,
 Position = 2,
 ParameterSetName = '',
 ValueFromPipeline = $True)]
 [string]$StaUrl
 )

 #Check if there is a valid NetScaler session active
 if ($nssession -eq $null) {
 write-host -ForegroundColor Red "NetScaler Login is required to continue, please use Login-NetScaler, quitting"
 break
 }


 #Set up the NetScaler Url for NITRO
 $Url = "$NSIP/nitro/v1/config/vpnvserver_staserver_binding"

 #Set the HTTP Method
 $Method = "POST"

 #Set the Request Header for Content Type
 $ContentType = "application/json"
 
 #Set up the JSON Payload to send to the netscaler
 $PayLoad = ConvertTo-JSON @{
 "vpnvserver_staserver_binding"=@{
 "name"=$Name;
 "staserver"=$StaUrl
 }
 }

 #Execute the NetScaler Nitro Command and catch the output. If error then break the function
 Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Body $Payload -Method $Method
 cls
 write-host -ForegroundColor Green "LDAP Policy Binding Complete"

}