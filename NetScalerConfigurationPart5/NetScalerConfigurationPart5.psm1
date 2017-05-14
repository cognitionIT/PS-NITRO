<# 
.SYNOPSIS
    This module file contains NetScaler Configuration functions.
.DESCRIPTION
    This module file contains NetScaler Configuration functions.
.NOTES
    Copyright (c) Citrix Systems, Inc. All rights reserved.
#>
#Requires -Version 3

Set-StrictMode -Version Latest

#region Part 1

# Define default URL protocol to https, which can be changed by calling Set-Protocol function
$Script:NSURLProtocol = "https"

function Set-NSMgmtProtocol {
    <#
    .SYNOPSIS
        Set $Script:NSURLProtocol, this will be used for all subsequent invocation of NITRO APIs
    .DESCRIPTION
        Set $Script:NSURLProtocol
    .PARAMETER Protocol
        Protocol, acceptable values are "http" and "https"
    .EXAMPLE
        Set-Protocol -Protocol https
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [ValidateSet("http","https")] [string]$Protocol
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $Script:NSURLProtocol = $Protocol

    Write-Verbose "Citrix NSURLProtocol set to $Script:NSURLProtocol"

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Get-NSMgmtProtocol {
    <#
    .SYNOPSIS
        Get the value of $Script:NSURLProtocol
    .DESCRIPTION
        Set $Script:NSURLProtocol
    .EXAMPLE
        $protocol  = Get-Protocol
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param()

    return $Script:NSURLProtocol 
}

function Connect-NSAppliance {
    <#
    .SYNOPSIS
        Connect to NetScaler Appliance
    .DESCRIPTION
        Connect to NetScaler Appliance. A custom web request session object will be returned
    .PARAMETER NSAddress
        NetScaler Management IP address
    .PARAMETER NSName
        NetScaler DNS name or FQDN
    .PARAMETER NSUserName
        UserName to access the NetScaler appliance
    .PARAMETER NSPassword
        Password to access the NetScaler appliance
    .PARAMETER Timeout
        Timeout in seconds to for the token of the connection to the NetScaler appliance. 900 is the default admin configured value.
    .EXAMPLE
         $Session = Connect-NSAppliance -NSAddress 10.108.151.1
    .EXAMPLE
         $Session = Connect-NSAppliance -NSName mynetscaler.mydomain.com
    .OUTPUTS
        CustomPSObject
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='Address')] [string]$NSAddress,
        [Parameter(Mandatory=$true,ParameterSetName='Name')] [string]$NSName,
        [Parameter(Mandatory=$false)] [string]$NSUserName="nsroot", 
        [Parameter(Mandatory=$false)] [string]$NSPassword="nsroot",
        [Parameter(Mandatory=$false)] [int]$Timeout=900
    )
    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    if ($PSCmdlet.ParameterSetName -eq 'Address') {
        Write-Verbose "Validating IP Address"
        $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
        if (-not [System.Net.IPAddress]::TryParse($NSAddress,[ref]$IPAddressObj)) {
            throw "'$NSAddress' is an invalid IP address"
        }
        $nsEndpoint = $NSAddress
    } elseif ($PSCmdlet.ParameterSetName -eq 'Name') {
        $nsEndpoint = $NSName
    }


    $login = @{"login" = @{"username"=$NSUserName;"password"=$NSPassword;"timeout"=$Timeout}}
    $loginJson = ConvertTo-Json $login
    
    try {
        Write-Verbose "Calling Invoke-RestMethod for login"
        $response = Invoke-RestMethod -Uri "$($Script:NSURLProtocol)://$nsEndpoint/nitro/v1/config/login" -Body $loginJson -Method POST -SessionVariable saveSession -ContentType application/json
                
        if ($response.severity -eq "ERROR") {
            throw "Error. See response: `n$($response | fl * | Out-String)"
        } else {
            Write-Verbose "Response:`n$(ConvertTo-Json $response | Out-String)"
        }
    }
    catch [Exception] {
        throw $_
    }


    $nsSession = New-Object -TypeName PSObject
    $nsSession | Add-Member -NotePropertyName Endpoint -NotePropertyValue $nsEndpoint -TypeName String
    $nsSession | Add-Member -NotePropertyName WebSession  -NotePropertyValue $saveSession -TypeName Microsoft.PowerShell.Commands.WebRequestSession

    Write-Verbose "$($MyInvocation.MyCommand): Exit"

    return $nsSession
}

function Disconnect-NSAppliance {
    <#
    .SYNOPSIS
        Disconnect NetScaler Appliance session
    .DESCRIPTION
        Disconnect NetScaler Appliance session
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .EXAMPLE
        Disconnect-NSAppliance -NSSession $Session
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $logout = @{"logout" = @{}}
    $logoutJson = ConvertTo-Json $logout
    
    try {
        Write-Verbose "Calling Invoke-RestMethod for logout"
        $response = Invoke-RestMethod -Uri "$($Script:NSURLProtocol)://$($NSSession.Endpoint)/nitro/v1/config/logout" -Body $logoutJson -Method POST -ContentType application/json -WebSession $NSSession.WebSession
    }
    catch [Exception] {
        throw $_
    }

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Invoke-NSNitroRestApi {
    <#
    .SYNOPSIS
        Invoke NetScaler NITRO REST API 
    .DESCRIPTION
        Invoke NetScaler NITRO REST API 
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER OperationMethod
        Specifies the method used for the web request
    .PARAMETER ResourceType
        Type of the NS appliance resource
    .PARAMETER ResourceName
        Name of the NS appliance resource, optional
    .PARAMETER Action
        Name of the action to perform on the NS appliance resource
    .PARAMETER Payload
        Payload  of the web request, in hashtable format
    .PARAMETER GetWarning
        Switch parameter, when turned on, warning message will be sent in 'message' field and 'WARNING' value is set in severity field of the response in case there is a warning.
        Turned off by default
    .PARAMETER OnErrorAction
        Use this parameter to set the onerror status for nitro request. Applicable only for bulk requests.
        Acceptable values: "EXIT", "CONTINUE", "ROLLBACK", default to "EXIT"
    .EXAMPLE
        Invoke NITRO REST API to add a DNS Server resource.
        $payload = @{ip="10.8.115.210"}
        Invoke-NSNitroRestApi -NSSession $Session -OperationMethod POST -ResourceType dnsnameserver -Payload $payload -Action add
    .OUTPUTS
        Only when the OperationMethod is GET:
        PSCustomObject that represents the JSON response content. This object can be manipulated using the ConvertTo-Json Cmdlet.
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession, 
        [Parameter(Mandatory=$true)] [ValidateSet("DELETE","GET","POST","PUT")] [string]$OperationMethod,
        [Parameter(Mandatory=$true)] [string]$ResourceType,
        [Parameter(Mandatory=$false)] [string]$ResourceName, 
        [Parameter(Mandatory=$false)] [string]$Action,
        [Parameter(Mandatory=$false)] [ValidateScript({$OperationMethod -eq "GET"})] [hashtable]$Arguments=@{},
        [Parameter(Mandatory=$false)] [ValidateScript({$OperationMethod -ne "GET"})] [hashtable]$Payload=@{},
        [Parameter(Mandatory=$false)] [switch]$GetWarning=$false,
        [Parameter(Mandatory=$false)] [ValidateSet("EXIT", "CONTINUE", "ROLLBACK")] [string]$OnErrorAction="EXIT"
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
    Write-Verbose "Building URI"
    $uri = "$($Script:NSURLProtocol)://$($NSSession.Endpoint)/nitro/v1/config/$ResourceType"
    if (-not [string]::IsNullOrEmpty($ResourceName)) {
        $uri += "/$ResourceName"
    }
    if ($OperationMethod -ne "GET") {
        if (-not [string]::IsNullOrEmpty($Action)) {
            $uri += "?action=$Action"
        }
    } else {
        if ($Arguments.Count -gt 0) {
            $uri += "?args="
            $argsList = @()
            foreach ($arg in $Arguments.GetEnumerator()) {
                $argsList += "$($arg.Name):$([System.Uri]::EscapeDataString($arg.Value))"
            }
            $uri += $argsList -join ','
        }
        #TODO: Add filter, view, and pagesize
    }
    Write-Verbose "URI: $uri"

    if ($OperationMethod -ne "GET") {
        Write-Verbose "Building Payload"
        $warning = if ($GetWarning) { "YES" } else { "NO" }
        $hashtablePayload = @{}
        $hashtablePayload."params" = @{"warning"=$warning;"onerror"=$OnErrorAction;<#"action"=$Action#>}
        $hashtablePayload.$ResourceType = $Payload
        $jsonPayload = ConvertTo-Json $hashtablePayload -Depth ([int]::MaxValue)
        Write-Verbose "JSON Payload:`n$jsonPayload"
    }

    try {
        Write-Verbose "Calling Invoke-RestMethod"
        $restParams = @{
            Uri = $uri
            ContentType = "application/json"
            Method = $OperationMethod
            WebSession = $NSSession.WebSession
            ErrorVariable = "restError"
        }
        
        if ($OperationMethod -ne "GET") {
            $restParams.Add("Body",$jsonPayload)
        }

        $response = Invoke-RestMethod @restParams
        
        if ($response) {
            if ($response.severity -eq "ERROR") {
                throw "Error. See response: `n$($response | fl * | Out-String)"
            } else {
                Write-Verbose "Response:`n$(ConvertTo-Json $response | Out-String)"
            }
        }
    }
    catch [Exception] {
        if ($ResourceType -eq "reboot" -and $restError[0].Message -eq "The underlying connection was closed: The connection was closed unexpectedly.") {
            Write-Verbose "Connection closed due to reboot"
        } else {
            throw $_
        }
    }

    Write-Verbose "$($MyInvocation.MyCommand): Exit"

    if ($OperationMethod -eq "GET") {
        return $response
    }
}

#endregion


#region Part 2

function Save-NSConfig {
    <#
    .SYNOPSIS
        Save NetScaler Config File 
    .DESCRIPTION
        Save NetScaler Config File 
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .EXAMPLE
        Save-NSConfig -NSSession $Session
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter" 
    
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsconfig -Action "save"

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Restart-NSAppliance {
    <#
    .SYNOPSIS
        Restart NetScaler Appliance, with an option to save NetScaler Config File before rebooting
    .DESCRIPTION
        Restart NetScaler Appliance, with an option to save NetScaler Config File before rebooting
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER SaveNSConfig
        Switch Parameter to save NetScaler Config file before rebooting.
    .PARAMETER WarmReboot
        Switch Parameter to perform warm reboot of the NetScaler appliance
    .PARAMETER Wait
        Switch Parameter to wait after reboot until Nitro REST API is online
    .PARAMETER WaitTimeout
        Timeout in seconds for the wait after reboot
    .EXAMPLE
        Save NetScaler Config file and restart NetScaler VPX
        Restart-NSAppliance -NSIP 10.108.151.1 -SaveNSConfig -WebSession $session
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$false)] [switch]$SaveNSConfig,
        [Parameter(Mandatory=$false)] [switch]$WarmReboot,
        [Parameter(Mandatory=$false)] [switch]$Wait,
        [Parameter(Mandatory=$false)] [int]$WaitTimeout=900
    )
    Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
    if ($SaveNSConfig) {
        Save-NSConfig -NSSession $NSSession
    }
    
    $canWait = $true
    $endpoint = $NSSession.Endpoint
    $ping = New-Object System.Net.NetworkInformation.Ping

    $payload = @{warm=$WarmReboot.ToBool()}
    $result = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType reboot -Payload $payload -Action reboot

    if ($Wait) {
        Write-Verbose "Start waiting process..."
        $waitStart = Get-Date
        Write-Verbose "Trying to ping until unreachable to ensure reboot process"
        while ($canWait -and $($ping.Send($endpoint,2000)).Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
            if ($($(Get-Date) - $waitStart).TotalSeconds -gt $WaitTimeout) {
                $canWait = $false
                break
            } else {
                Write-Verbose "Still reachable. Pinging again..."
                Start-Sleep -Seconds 1
            }
        } 

        if ($canWait) {
            Write-Verbose "Trying to reach Nitro REST API to test connectivity..."       
            while ($canWait) {
                $connectTestError = $null
                $response = $null
                try {
                    $response = Invoke-RestMethod -Uri "$($Script:NSURLProtocol)://$endpoint/nitro/v1/config" -Method GET -ContentType application/json -ErrorVariable connectTestError
                }
                catch {
                    if ($connectTestError) {
                        if ($connectTestError.InnerException.Message -eq "The remote server returned an error: (401) Unauthorized.") {
                            break
                        } elseif ($($(Get-Date) - $waitStart).TotalSeconds -gt $WaitTimeout) {
                            $canWait = $false
                            break
                        } else {
                            Write-Verbose "Nitro REST API is not responding. Trying again..."
                            Start-Sleep -Seconds 1
                        }
                    }
                }
                if ($response) {
                    break
                }
            }
        }

        if ($canWait) {
            Write-Verbose "NetScaler appliance is back online."
        } else {
            throw "Timeout expired. Unable to determine if NetScaler appliance is back online."
        }
    }

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Add-NSIPResource {
    <#
    .SYNOPSIS
        Create NetScaler IP resource(s)
    .DESCRIPTION
        Create NetScaler IP resource(s)
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER IPAddress
        IPv4 address to create on the NetScaler appliance. Cannot be changed after the IP address is created
    .PARAMETER SubnetMask
        Subnet mask associated with the IP address
    .PARAMETER Type
        Type of the IP address to create on the NetScaler appliance. Cannot be changed after the IP address is created
        Allowed values are "SNIP", "VIP", "MIP", "NSIP", "GSLBsiteIP", "CLIP", default to SNIP"
    .PARAMETER VServer
        Specify to use enable the vserver attribute for this IP entity
    .PARAMETER MgmtAccess
        Specify to allow access to management applications on this IP address
    .EXAMPLE
        Add Subnet IP
        Add-NSIPResource -NSSession $Session -IPAddress "10.108.151.2" -SubnetMask "255.255.248.0"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] [string]$IPAddress,
        [Parameter(Mandatory=$true)] [string]$SubnetMask,
        [Parameter(Mandatory=$false)] [ValidateSet("SNIP", "VIP", "MIP", "NSIP", "GSLBsiteIP", "CLIP")] [string]$Type="SNIP",
        [Parameter(Mandatory=$false)] [switch]$VServer,
        [Parameter(Mandatory=$false)] [switch]$MgmtAccess
    )
    Begin {
        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $vserverState = if ($VServer) { "ENABLED" } else { "DISABLED" }
        $mgmtAccessState = if ($MgmtAccess) { "ENABLED" } else { "DISABLED" }
        
        Write-Verbose "Validating Subnet Mask"
        $SubnetMaskObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
        if (-not [System.Net.IPAddress]::TryParse($SubnetMask,[ref]$SubnetMaskObj) -or $SubnetMaskObj.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
            throw "'$SubnetMask' is an invalid IPv4 subnet mask"
        }
    }
    Process {
        Write-Verbose "Validating IP Address"
        $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
        if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj) -or $IPAddressObj.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
            throw "'$IPAddress' is an invalid IPv4 address"
        }
        
        $payload = @{ipaddress=$IPAddress;netmask=$SubnetMask;type=$Type;vserver=$vserverState;mgmtaccess=$mgmtAccessState}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsip -Payload $payload -Action add
    }
    End {
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
}

function Set-NSHostName {
    <#
    .SYNOPSIS
        Set NetScaler Appliance Hostname
    .DESCRIPTION
        Set NetScaler Appliance Hostname
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER HostName
        Host name for the NetScaler appliance
    .EXAMPLE
         Set-NSHostName -NSSession $Session -HostName "sslvpn-sg"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$HostName
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $payload = @{hostname=$HostName}
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType nshostname -Payload $payload -Action update

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Set-NSTimeZone {
    <#
    .SYNOPSIS
        Set NetScaler Appliance Timezone
    .DESCRIPTION
        Set NetScaler Appliance Timezone
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER TimeZone
        Valid NetScaler specific name of the timezone. e.g. "GMT-05:00-EST-America/Panama"
        For more information on valid names run Import-NSTimeZones which returns a list of all timezones.
    .EXAMPLE
         Set-NSTimeZone -NSSession $Session -TimeZone "GMT-05:00-EST-America/Panama"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [ValidateScript({
            if ($NSTimeZones -contains $_) {
                $true
            } else {
                throw "Valid values are: $($NSTimeZones -join ', ')"
            }
        })] [string]$TimeZone
    )
    
    Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
    $payload = @{timezone=$TimeZone}
    $Job = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType nsconfig -Payload $payload -Action update 

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Import-NSTimeZones {
    #Count is 411 time zones
    return @(
        'CoordinatedUniversalTime',
        'GMT+00:00-GMT-Africa/Abidjan','GMT+00:00-GMT-Africa/Accra','GMT+00:00-GMT-Africa/Bamako','GMT+00:00-GMT-Africa/Banjul','GMT+00:00-GMT-Africa/Bissau','GMT+00:00-GMT-Africa/Conakry','GMT+00:00-GMT-Africa/Dakar','GMT+00:00-GMT-Africa/Freetown','GMT+00:00-GMT-Africa/Lome','GMT+00:00-GMT-Africa/Monrovia','GMT+00:00-GMT-Africa/Nouakchott','GMT+00:00-GMT-Africa/Ouagadougou','GMT+00:00-GMT-Africa/Sao_Tome','GMT+00:00-GMT-America/Danmarkshavn','GMT+00:00-GMT-Atlantic/Reykjavik','GMT+00:00-GMT-Atlantic/St_Helena','GMT+00:00-GMT-Europe/Dublin','GMT+00:00-GMT-Europe/Guernsey','GMT+00:00-GMT-Europe/Isle_of_Man','GMT+00:00-GMT-Europe/Jersey','GMT+00:00-GMT-Europe/London','GMT+00:00-WET-Africa/Casablanca','GMT+00:00-WET-Africa/El_Aaiun','GMT+00:00-WET-Atlantic/Canary','GMT+00:00-WET-Atlantic/Faroe','GMT+00:00-WET-Atlantic/Madeira','GMT+00:00-WET-Europe/Lisbon',
        'GMT+01:00-CET-Africa/Algiers','GMT+01:00-CET-Africa/Ceuta','GMT+01:00-CET-Africa/Tunis','GMT+01:00-CET-Arctic/Longyearbyen','GMT+01:00-CET-Europe/Amsterdam','GMT+01:00-CET-Europe/Andorra','GMT+01:00-CET-Europe/Belgrade','GMT+01:00-CET-Europe/Berlin','GMT+01:00-CET-Europe/Bratislava','GMT+01:00-CET-Europe/Brussels','GMT+01:00-CET-Europe/Budapest','GMT+01:00-CET-Europe/Copenhagen','GMT+01:00-CET-Europe/Gibraltar','GMT+01:00-CET-Europe/Ljubljana','GMT+01:00-CET-Europe/Luxembourg','GMT+01:00-CET-Europe/Madrid','GMT+01:00-CET-Europe/Malta','GMT+01:00-CET-Europe/Monaco','GMT+01:00-CET-Europe/Oslo','GMT+01:00-CET-Europe/Paris','GMT+01:00-CET-Europe/Podgorica','GMT+01:00-CET-Europe/Prague','GMT+01:00-CET-Europe/Rome','GMT+01:00-CET-Europe/San_Marino','GMT+01:00-CET-Europe/Sarajevo','GMT+01:00-CET-Europe/Skopje','GMT+01:00-CET-Europe/Stockholm','GMT+01:00-CET-Europe/Tirane','GMT+01:00-CET-Europe/Vaduz','GMT+01:00-CET-Europe/Vatican','GMT+01:00-CET-Europe/Vienna','GMT+01:00-CET-Europe/Warsaw','GMT+01:00-CET-Europe/Zagreb','GMT+01:00-CET-Europe/Zurich','GMT+01:00-WAT-Africa/Bangui','GMT+01:00-WAT-Africa/Brazzaville','GMT+01:00-WAT-Africa/Douala','GMT+01:00-WAT-Africa/Kinshasa','GMT+01:00-WAT-Africa/Lagos','GMT+01:00-WAT-Africa/Libreville','GMT+01:00-WAT-Africa/Luanda','GMT+01:00-WAT-Africa/Malabo','GMT+01:00-WAT-Africa/Ndjamena','GMT+01:00-WAT-Africa/Niamey','GMT+01:00-WAT-Africa/Porto-Novo',
        'GMT+02:00-CAT-Africa/Blantyre','GMT+02:00-CAT-Africa/Bujumbura','GMT+02:00-CAT-Africa/Gaborone','GMT+02:00-CAT-Africa/Harare','GMT+02:00-CAT-Africa/Kigali','GMT+02:00-CAT-Africa/Lubumbashi','GMT+02:00-CAT-Africa/Lusaka','GMT+02:00-CAT-Africa/Maputo','GMT+02:00-EET-Africa/Cairo','GMT+02:00-EET-Africa/Tripoli','GMT+02:00-EET-Asia/Amman','GMT+02:00-EET-Asia/Beirut','GMT+02:00-EET-Asia/Damascus','GMT+02:00-EET-Asia/Gaza','GMT+02:00-EET-Asia/Hebron','GMT+02:00-EET-Asia/Nicosia','GMT+02:00-EET-Europe/Athens','GMT+02:00-EET-Europe/Bucharest','GMT+02:00-EET-Europe/Chisinau','GMT+02:00-EET-Europe/Helsinki','GMT+02:00-EET-Europe/Istanbul','GMT+02:00-EET-Europe/Kiev','GMT+02:00-EET-Europe/Mariehamn','GMT+02:00-EET-Europe/Riga','GMT+02:00-EET-Europe/Simferopol','GMT+02:00-EET-Europe/Sofia','GMT+02:00-EET-Europe/Tallinn','GMT+02:00-EET-Europe/Uzhgorod','GMT+02:00-EET-Europe/Vilnius','GMT+02:00-EET-Europe/Zaporozhye','GMT+02:00-IST-Asia/Jerusalem','GMT+02:00-SAST-Africa/Johannesburg','GMT+02:00-SAST-Africa/Maseru','GMT+02:00-SAST-Africa/Mbabane','GMT+02:00-WAST-Africa/Windhoek',
        'GMT+03:00-AST-Asia/Aden','GMT+03:00-AST-Asia/Baghdad','GMT+03:00-AST-Asia/Bahrain','GMT+03:00-AST-Asia/Kuwait','GMT+03:00-AST-Asia/Qatar','GMT+03:00-AST-Asia/Riyadh','GMT+03:00-EAT-Africa/Addis_Ababa','GMT+03:00-EAT-Africa/Asmara','GMT+03:00-EAT-Africa/Dar_es_Salaam','GMT+03:00-EAT-Africa/Djibouti','GMT+03:00-EAT-Africa/Kampala','GMT+03:00-EAT-Africa/Khartoum','GMT+03:00-EAT-Africa/Mogadishu','GMT+03:00-EAT-Africa/Nairobi','GMT+03:00-EAT-Indian/Antananarivo','GMT+03:00-EAT-Indian/Comoro','GMT+03:00-EAT-Indian/Mayotte','GMT+03:00-FET-Europe/Kaliningrad','GMT+03:00-FET-Europe/Minsk','GMT+03:00-SYOT-Antarctica/Syowa',
        'GMT+03:30-IRST-Asia/Tehran',
        'GMT+04:00-AMT-Asia/Yerevan','GMT+04:00-AZT-Asia/Baku','GMT+04:00-GET-Asia/Tbilisi','GMT+04:00-GST-Asia/Dubai','GMT+04:00-GST-Asia/Muscat','GMT+04:00-MSK-Europe/Moscow','GMT+04:00-MUT-Indian/Mauritius','GMT+04:00-RET-Indian/Reunion','GMT+04:00-SAMT-Europe/Samara','GMT+04:00-SCT-Indian/Mahe','GMT+04:00-VOLT-Europe/Volgograd',
        'GMT+04:30-AFT-Asia/Kabul',
        'GMT+05:00-AQTT-Asia/Aqtau','GMT+05:00-AQTT-Asia/Aqtobe','GMT+05:00-MAWT-Antarctica/Mawson','GMT+05:00-MVT-Indian/Maldives',
        'GMT+05:00-ORAT-Asia/Oral','GMT+05:00-PKT-Asia/Karachi','GMT+05:00-TFT-Indian/Kerguelen','GMT+05:00-TJT-Asia/Dushanbe','GMT+05:00-TMT-Asia/Ashgabat','GMT+05:00-UZT-Asia/Samarkand','GMT+05:00-UZT-Asia/Tashkent',
        'GMT+05:30-IST-Asia/Colombo','GMT+05:30-IST-Asia/Kolkata',
        'GMT+05:45-NPT-Asia/Kathmandu',
        'GMT+06:00-ALMT-Asia/Almaty','GMT+06:00-BDT-Asia/Dhaka','GMT+06:00-BTT-Asia/Thimphu','GMT+06:00-IOT-Indian/Chagos','GMT+06:00-KGT-Asia/Bishkek','GMT+06:00-QYZT-Asia/Qyzylorda','GMT+06:00-VOST-Antarctica/Vostok','GMT+06:00-YEKT-Asia/Yekaterinburg',
        'GMT+06:30-CCT-Indian/Cocos','GMT+06:30-MMT-Asia/Rangoon',
        'GMT+07:00-CXT-Indian/Christmas','GMT+07:00-DAVT-Antarctica/Davis','GMT+07:00-HOVT-Asia/Hovd','GMT+07:00-ICT-Asia/Bangkok','GMT+07:00-ICT-Asia/Ho_Chi_Minh','GMT+07:00-ICT-Asia/Phnom_Penh','GMT+07:00-ICT-Asia/Vientiane','GMT+07:00-NOVT-Asia/Novokuznetsk','GMT+07:00-NOVT-Asia/Novosibirsk','GMT+07:00-OMST-Asia/Omsk','GMT+07:00-WIT-Asia/Jakarta','GMT+07:00-WIT-Asia/Pontianak',
        'GMT+08:00-BNT-Asia/Brunei','GMT+08:00-CHOT-Asia/Choibalsan','GMT+08:00-CIT-Asia/Makassar','GMT+08:00-CST-Asia/Chongqing','GMT+08:00-CST-Asia/Harbin','GMT+08:00-CST-Asia/Kashgar','GMT+08:00-CST-Asia/Macau','GMT+08:00-CST-Asia/Shanghai','GMT+08:00-CST-Asia/Taipei','GMT+08:00-CST-Asia/Urumqi','GMT+08:00-HKT-Asia/Hong_Kong','GMT+08:00-KRAT-Asia/Krasnoyarsk','GMT+08:00-MYT-Asia/Kuala_Lumpur','GMT+08:00-MYT-Asia/Kuching','GMT+08:00-PHT-Asia/Manila','GMT+08:00-SGT-Asia/Singapore','GMT+08:00-ULAT-Asia/Ulaanbaatar','GMT+08:00-WST-Antarctica/Casey','GMT+08:00-WST-Australia/Perth',
        'GMT+08:45-CWST-Australia/Eucla',
        'GMT+09:00-EIT-Asia/Jayapura','GMT+09:00-IRKT-Asia/Irkutsk','GMT+09:00-JST-Asia/Tokyo','GMT+09:00-KST-Asia/Pyongyang','GMT+09:00-KST-Asia/Seoul','GMT+09:00-PWT-Pacific/Palau','GMT+09:00-TLT-Asia/Dili',
        'GMT+09:30-CST-Australia/Darwin',
        'GMT+10:00-ChST-Pacific/Guam','GMT+10:00-ChST-Pacific/Saipan','GMT+10:00-CHUT-Pacific/Chuuk','GMT+10:00-DDUT-Antarctica/DumontDUrville','GMT+10:00-EST-Australia/Brisbane','GMT+10:00-EST-Australia/Lindeman','GMT+10:00-PGT-Pacific/Port_Moresby','GMT+10:00-YAKT-Asia/Yakutsk',
        'GMT+10:30-CST-Australia/Adelaide','GMT+10:30-CST-Australia/Broken_Hill',
        'GMT+11:00-EST-Australia/Currie','GMT+11:00-EST-Australia/Hobart','GMT+11:00-EST-Australia/Melbourne','GMT+11:00-EST-Australia/Sydney','GMT+11:00-KOST-Pacific/Kosrae','GMT+11:00-LHST-Australia/Lord_Howe','GMT+11:00-MIST-Antarctica/Macquarie','GMT+11:00-NCT-Pacific/Noumea','GMT+11:00-PONT-Pacific/Pohnpei','GMT+11:00-SAKT-Asia/Sakhalin','GMT+11:00-SBT-Pacific/Guadalcanal','GMT+11:00-VLAT-Asia/Vladivostok','GMT+11:00-VUT-Pacific/Efate',
        'GMT+11:30-NFT-Pacific/Norfolk',
        'GMT+12:00-ANAT-Asia/Anadyr','GMT+12:00-FJT-Pacific/Fiji','GMT+12:00-GILT-Pacific/Tarawa','GMT+12:00-MAGT-Asia/Magadan','GMT+12:00-MHT-Pacific/Kwajalein','GMT+12:00-MHT-Pacific/Majuro','GMT+12:00-NRT-Pacific/Nauru','GMT+12:00-PETT-Asia/Kamchatka','GMT+12:00-TVT-Pacific/Funafuti','GMT+12:00-WAKT-Pacific/Wake','GMT+12:00-WFT-Pacific/Wallis',
        'GMT+13:00-NZDT-Antarctica/McMurdo',
        'GMT+13:00-NZDT-Antarctica/South_Pole','GMT+13:00-NZDT-Pacific/Auckland','GMT+13:00-PHOT-Pacific/Enderbury','GMT+13:00-TOT-Pacific/Tongatapu',
        'GMT+13:45-CHADT-Pacific/Chatham',
        'GMT+14:00-LINT-Pacific/Kiritimati','GMT+14:00-WSDT-Pacific/Apia',
        'GMT-01:00-AZOT-Atlantic/Azores','GMT-01:00-CVT-Atlantic/Cape_Verde','GMT-01:00-EGT-America/Scoresbysund',
        'GMT-02:00-FNT-America/Noronha','GMT-02:00-GST-Atlantic/South_Georgia','GMT-02:00-PMDT-America/Miquelon',
        'GMT-02:30-NDT-America/St_Johns',
        'GMT-03:00-ADT-America/Glace_Bay','GMT-03:00-ADT-America/Goose_Bay','GMT-03:00-ADT-America/Halifax','GMT-03:00-ADT-America/Moncton','GMT-03:00-ADT-America/Thule','GMT-03:00-ADT-Atlantic/Bermuda','GMT-03:00-ART-America/Argentina/Buenos_Aires','GMT-03:00-ART-America/Argentina/Catamarca','GMT-03:00-ART-America/Argentina/Cordoba','GMT-03:00-ART-America/Argentina/Jujuy','GMT-03:00-ART-America/Argentina/La_Rioja','GMT-03:00-ART-America/Argentina/Mendoza','GMT-03:00-ART-America/Argentina/Rio_Gallegos','GMT-03:00-ART-America/Argentina/Salta','GMT-03:00-ART-America/Argentina/San_Juan','GMT-03:00-ART-America/Argentina/Tucuman','GMT-03:00-ART-America/Argentina/Ushuaia','GMT-03:00-BRT-America/Araguaina','GMT-03:00-BRT-America/Bahia','GMT-03:00-BRT-America/Belem','GMT-03:00-BRT-America/Fortaleza','GMT-03:00-BRT-America/Maceio','GMT-03:00-BRT-America/Recife','GMT-03:00-BRT-America/Santarem','GMT-03:00-BRT-America/Sao_Paulo','GMT-03:00-FKST-Atlantic/Stanley','GMT-03:00-GFT-America/Cayenne','GMT-03:00-PYST-America/Asuncion','GMT-03:00-ROTT-Antarctica/Rothera','GMT-03:00-SRT-America/Paramaribo','GMT-03:00-UYT-America/Montevideo','GMT-03:00-WARST-America/Argentina/San_Luis','GMT-03:00-WGT-America/Godthab',
        'GMT-04:00-AMT-America/Boa_Vista','GMT-04:00-AMT-America/Campo_Grande','GMT-04:00-AMT-America/Cuiaba','GMT-04:00-AMT-America/Eirunepe','GMT-04:00-AMT-America/Manaus','GMT-04:00-AMT-America/Porto_Velho','GMT-04:00-AMT-America/Rio_Branco','GMT-04:00-AST-America/Anguilla','GMT-04:00-AST-America/Antigua','GMT-04:00-AST-America/Aruba','GMT-04:00-AST-America/Barbados','GMT-04:00-AST-America/Blanc-Sablon','GMT-04:00-AST-America/Dominica','GMT-04:00-AST-America/Grenada','GMT-04:00-AST-America/Guadeloupe','GMT-04:00-AST-America/Marigot','GMT-04:00-AST-America/Martinique','GMT-04:00-AST-America/Montserrat','GMT-04:00-AST-America/Port_of_Spain','GMT-04:00-AST-America/Puerto_Rico','GMT-04:00-AST-America/Santo_Domingo','GMT-04:00-AST-America/St_Barthelemy','GMT-04:00-AST-America/St_Kitts','GMT-04:00-AST-America/St_Lucia','GMT-04:00-AST-America/St_Thomas','GMT-04:00-AST-America/St_Vincent','GMT-04:00-AST-America/Tortola','GMT-04:00-BOT-America/La_Paz','GMT-04:00-CDT-America/Havana','GMT-04:00-CLT-America/Santiago','GMT-04:00-CLT-Antarctica/Palmer','GMT-04:00-EDT-America/Detroit','GMT-04:00-EDT-America/Grand_Turk','GMT-04:00-EDT-America/Indiana/Indianapolis','GMT-04:00-EDT-America/Indiana/Marengo','GMT-04:00-EDT-America/Indiana/Petersburg','GMT-04:00-EDT-America/Indiana/Vevay','GMT-04:00-EDT-America/Indiana/Vincennes','GMT-04:00-EDT-America/Indiana/Winamac','GMT-04:00-EDT-America/Iqaluit','GMT-04:00-EDT-America/Kentucky/Louisville','GMT-04:00-EDT-America/Kentucky/Monticello','GMT-04:00-EDT-America/Montreal','GMT-04:00-EDT-America/Nassau','GMT-04:00-EDT-America/New_York','GMT-04:00-EDT-America/Nipigon','GMT-04:00-EDT-America/Pangnirtung','GMT-04:00-EDT-America/Thunder_Bay','GMT-04:00-EDT-America/Toronto','GMT-04:00-GYT-America/Guyana',
        'GMT-04:30-VET-America/Caracas',
        'GMT-05:00-CDT-America/Chicago','GMT-05:00-CDT-America/Indiana/Knox','GMT-05:00-CDT-America/Indiana/Tell_City','GMT-05:00-CDT-America/Matamoros','GMT-05:00-CDT-America/Menominee','GMT-05:00-CDT-America/North_Dakota/Beulah','GMT-05:00-CDT-America/North_Dakota/Center','GMT-05:00-CDT-America/North_Dakota/New_Salem','GMT-05:00-CDT-America/Rainy_River','GMT-05:00-CDT-America/Rankin_Inlet','GMT-05:00-CDT-America/Resolute','GMT-05:00-CDT-America/Winnipeg','GMT-05:00-COT-America/Bogota','GMT-05:00-ECT-America/Guayaquil','GMT-05:00-EST-America/Atikokan','GMT-05:00-EST-America/Cayman','GMT-05:00-EST-America/Jamaica','GMT-05:00-EST-America/Panama','GMT-05:00-EST-America/Port-au-Prince','GMT-05:00-PET-America/Lima',
        'GMT-06:00-CST-America/Bahia_Banderas','GMT-06:00-CST-America/Belize',
        'GMT-06:00-CST-America/Cancun','GMT-06:00-CST-America/Costa_Rica','GMT-06:00-CST-America/El_Salvador','GMT-06:00-CST-America/Guatemala','GMT-06:00-CST-America/Managua',
        'GMT-06:00-CST-America/Merida','GMT-06:00-CST-America/Mexico_City','GMT-06:00-CST-America/Monterrey','GMT-06:00-CST-America/Regina','GMT-06:00-CST-America/Swift_Current',
        'GMT-06:00-CST-America/Tegucigalpa','GMT-06:00-EAST-Pacific/Easter','GMT-06:00-GALT-Pacific/Galapagos','GMT-06:00-MDT-America/Boise','GMT-06:00-MDT-America/Cambridge_Bay',
        'GMT-06:00-MDT-America/Denver','GMT-06:00-MDT-America/Edmonton','GMT-06:00-MDT-America/Inuvik','GMT-06:00-MDT-America/Ojinaga','GMT-06:00-MDT-America/Shiprock',
        'GMT-06:00-MDT-America/Yellowknife',
        'GMT-07:00-MST-America/Chihuahua','GMT-07:00-MST-America/Dawson_Creek','GMT-07:00-MST-America/Hermosillo','GMT-07:00-MST-America/Mazatlan','GMT-07:00-MST-America/Phoenix','GMT-07:00-PDT-America/Dawson','GMT-07:00-PDT-America/Los_Angeles','GMT-07:00-PDT-America/Tijuana','GMT-07:00-PDT-America/Vancouver','GMT-07:00-PDT-America/Whitehorse',
        'GMT-08:00-AKDT-America/Anchorage','GMT-08:00-AKDT-America/Juneau','GMT-08:00-AKDT-America/Nome','GMT-08:00-AKDT-America/Sitka','GMT-08:00-AKDT-America/Yakutat','GMT-08:00-MeST-America/Metlakatla','GMT-08:00-PST-America/Santa_Isabel','GMT-08:00-PST-Pacific/Pitcairn',
        'GMT-09:00-GAMT-Pacific/Gambier','GMT-09:00-HADT-America/Adak',
        'GMT-09:30-MART-Pacific/Marquesas',
        'GMT-10:00-CKT-Pacific/Rarotonga','GMT-10:00-HST-Pacific/Honolulu','GMT-10:00-HST-Pacific/Johnston','GMT-10:00-TAHT-Pacific/Tahiti','GMT-10:00-TKT-Pacific/Fakaofo',
        'GMT-11:00-NUT-Pacific/Niue','GMT-11:00-SST-Pacific/Midway','GMT-11:00-SST-Pacific/Pago_Pago'
    )
}

Set-Variable -Name NSTimeZones -Value $(Import-NSTimeZones) -Option Constant

function Add-NSDnsNameServer {
    <#
    .SYNOPSIS
        Add domain name server resource
    .DESCRIPTION
        Add domain name server resource
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER DNSServerIPAddress
        IP address of an external name server
    .EXAMPLE
        [string[]]$DNSServers = @("10.8.115.210","10.8.115.211")
        $DNSServers | Add-NSDnsNameServer -NSSession $Session 
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] [string]$DNSServerIPAddress
    )
    Begin {
        Write-Verbose "$($MyInvocation.MyCommand): Enter"
    }
    Process {
        Write-Verbose "Validating IP Address"
        $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
        if (-not [System.Net.IPAddress]::TryParse($DNSServerIPAddress,[ref]$IPAddressObj)) {
            throw "'$DNSServerIPAddress' is an invalid IP address"
        }

        $payload = @{ip=$DNSServerIPAddress}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType dnsnameserver -Payload $payload -Action add
    }
    End {
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }

}

function Send-NSLicenseViaPSCP {    
    <#
    .SYNOPSIS
        Uploading the license file(s) to NetScaler appliance via Putty's PSCP
    .DESCRIPTION
        Uploading the license file(s) to license folder of NetScaler appliance. Destination file names are the same as source file names
    .Parameter NSIP
        NetScaler Management IPAddress
    .Parameter NSUserName
        UserName to access the NetScaler Managerment Console, default to nsroot
    .Parameter NSPassword
        Password to access the NetScaler Managerment Console, default to nsroot
    .Parameter PathToLicenseFile
        Full path to the source of the licenseFile, allow value from Pipeline
    .Parameter PathToPSCP
        Full path to pscp.exe. If this is not provided then the environment paths are used.
    .EXAMPLE
        Send two license files to NetScaler appliance with IPAddress 10.108.151.1
        $licfiles = @("C:\NSLicense\CAG_Enterprise_VPX_2012.lic","C:\NSLicense\CAGU-Hostname_10000CCU_sslvpn-sg.lic")
        $licfiles | Send-NSLicenseViaPSCP -NSIP 10.108.151.1
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string] $NSIP, 
        [Parameter(Mandatory=$false)][string] $NSUserName="nsroot", 
        [Parameter(Mandatory=$false)][string] $NSPassword="nsroot",
        [Parameter(Mandatory=$true,  ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] [string] $PathToLicenseFile,
        [Parameter(Mandatory=$false)] [string] $PathToPSCP
    )
    Begin {
        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        if ([string]::IsNullOrEmpty($PathToPSCP)) {
            if (Get-Command "pscp.exe" -ErrorAction SilentlyContinue) {
                $pscp = "pscp.exe"
            } else {
                throw "Unable to find pscp.exe in the environment paths"
            }
        } else {
            if (-not $PathToPSCP.EndsWith("pscp") -or -not $PathToPSCP.EndsWith("pscp.exe")) {
                $PathToPSCP = $PathToPSCP.TrimEnd("\") + "\pscp.exe"
            }
            if (Get-Command $PathToPSCP -ErrorAction SilentlyContinue) {
                $pscp = $PathToPSCP
            } else {
                throw "Unable to find pscp.exe at '$PathToPSCP'"
            }
        }
    }
    Process {
        Write-Verbose "Upload license file $PathToLicenseFile to NetScaler appliance '$NSIP'"
        $licenseFileName = Split-Path -Path $PathToLicenseFile -Leaf
        $argsList = @('-l',"$NSUserName",'-pw',"$NSPassword","-r","-p",$PathToLicenseFile,"$($NSIP):/nsconfig/license/$licenseFileName")
        if ($output = & $pscp $argsList ) {
            # Check the end-of-line for multi-file copies
            (($output -join "`n") -split "`n`n") | % {
                if ( $_ -notmatch '100%\s*$' ) {
                    throw "Error occurred invoking 'pscp.exe $argsList' : $_"
                }
            }
        }
    } 
    End {
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }   
}

function Send-NSLicense {    
    <#
    .SYNOPSIS
        Uploading the license file(s) to NetScaler Appliance
    .DESCRIPTION
        Uploading the license file(s) to license folder of NetScaler Appliance. Destination file names are the same as source file names.

        This requires the Nitro Rest API version 10.5 or higher.
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER PathToLicenseFile
        Full path to the the Citrix license file
    .EXAMPLE
        Send two license files to NetScaler appliance
        $licfiles = @("C:\NSLicense\CAG_Enterprise_VPX_2012.lic","C:\NSLicense\CAGU-Hostname_10000CCU_sslvpn-sg.lic")
        $licfiles | Send-NSLicense -NSSession $session
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession, 
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] [string]$PathToLicenseFile
    )
    Begin {        
        Write-Verbose "$($MyInvocation.MyCommand): Enter"
    }
    Process {
        Write-Verbose "Upload license file '$PathToLicenseFile' to NetScaler '$($NSSession.Endpoint)'"
        $licenseFileName = Split-Path -Path $PathToLicenseFile -Leaf
        
        if (-not $licenseFileName.EndsWith(".lic",[StringComparison]::OrdinalIgnoreCase)) {
            throw "'$licenseFileName' file name is invalid. Valid Citrix license file names end in .lic."
        }
        
        $licenseContent = Get-Content $PathToLicenseFile -Encoding "Byte"

        $licenseContentBase64 = [System.Convert]::ToBase64String($licenseContent)

        $payload = @{filename=$licenseFileName;filecontent=$licenseContentBase64;filelocation="/nsconfig/license/";fileencoding="BASE64"}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemfile -Payload $payload -Action add
    } 
    End {
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }   
}

function Enable-NSFeature {
    <#
    .SYNOPSIS
        Enable NetScaler appliance feature(s)
    .DESCRIPTION
        Enable one or more NetScaler appliance feature(s)
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER Feature
        Feature(s) to be enabled. This can be passed as multiple features (comma or space separated).
    .EXAMPLE
        Enable-NSFeature -NSSession $Session -Feature "sslvpn"
    .EXAMPLE
        Enable-NSFeature -NSSession $Session -Feature "sslvpn","lb"
    .EXAMPLE
        Enable-NSFeature -NSSession $Session -Feature "sslvpn lb"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string[]]$Feature
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $featureParsed = $Feature.Trim().ToUpper() -join ' '

    $payload = @{feature=$featureParsed}
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsfeature -Payload $payload -Action enable

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Enable-NSMode {
    <#
    .SYNOPSIS
        Enable NetScaler appliance mode(s)
    .DESCRIPTION
        Enable one or more NetScaler appliance mode(s)
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER Mode
        Mode(s) to be enabled. This can be passed as multiple modes (comma or space separated).
    .EXAMPLE
        Enable-NSMode -NSSession $Session -Mode "usnip"
    .EXAMPLE
        Enable-NSMode -NSSession $Session -Mode "usnip","mbf"
    .EXAMPLE
        Enable-NSMode -NSSession $Session -Mode "usnip mbf"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string[]]$Mode
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $modeParsed = $Mode.Trim().ToUpper() -join ' '

    $payload = @{mode=$modeParsed}
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsmode -Payload $payload -Action enable

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

#endregion


#region Part 3

function Add-NSServerCertificate {
    <#
    .SYNOPSIS
        Add NetScaler Appliance Server Certificate
    .DESCRIPTION
        Add NetScaler Appliance Server Certificate by:
        -Creating the private RSA key
        -Creating the CSR
        -Downloading the CSR
        -Requesting the certificate
        -Uploading the certificate
        -Created the cert/key pair

        This requires the Nitro Rest API version 10.5 or higher.
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER CAName
        The FQDN of the Certification Authority host and Certification Authority name in the form CAHostNameFQDN\CAName
    .PARAMETER CommonName
        Fully qualified domain name for the company or web site.
        The common name must match the name used by DNS servers to do a DNS lookup of your server.
        Most browsers use this information for authenticating the server's certificate during the SSL handshake.
        If the server name in the URL does not match the common name as given in the server certificate, the browser terminates the SSL handshake or prompts the user with a warning message.
        Do not use wildcard characters, such as asterisk (*) or question mark (?), and do not use an IP address as the common name.
        The common name must not contain the protocol specifier or .
    .PARAMETER OrganizationName
        Name of the organization that will use this certificate.
        The organization name (corporation, limited partnership, university, or government agency) must be registered with some authority at the national, state, or city level.
        Use the legal name under which the organization is registered.
        Do not abbreviate the organization name and do not use the following characters in the name: Angle brackets (< >) tilde (~), exclamation mark, at (@), pound (#), zero (0), caret (^), asterisk (*), forward slash (/), square brackets ([ ]), question mark (?).
    .PARAMETER CountryName
        Two letter ISO code for your country. For example, US for United States.
    .PARAMETER StateName
        Full name of the state or province where your organization is located. Do not abbreviate.
    .PARAMETER KeyFileBits
        Size, in bits, of the private key.
    .EXAMPLE
         Add-NSServerCertificate -NSSession $Session
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$CAName,
        [Parameter(Mandatory=$true)] [ValidateLength(1,63)] [string]$CommonName,
        [Parameter(Mandatory=$true)] [ValidateLength(1,63)] [string]$OrganizationName,
        [Parameter(Mandatory=$true)] [ValidateLength(2,2)] [string]$CountryName,
        [Parameter(Mandatory=$true)] [ValidateLength(1,127)] [string]$StateName,
        [Parameter(Mandatory=$false)] [ValidateRange(512,4096)] [int]$KeyFileBits=2048
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $fileName = $CommonName -replace "\*","wildcard"
    
    $certKeyFileName= "$($fileName).key"
    $certReqFileName = "$($fileName).req"
    $certFileName = "$($fileName).cert"
    
    $certReqFileFull = "$($env:TEMP)\$certReqFileName"
    $certFileFull = "$($env:TEMP)\$certFileName"
    
    try {
        Write-Verbose "Creating RSA key file"
        $payload = @{keyfile=$certKeyFileName;bits=$KeyFileBits}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslrsakey -Payload $payload -Action create

        Write-Verbose "Creating certificate request"
        $payload = @{reqfile=$certReqFileName;keyfile=$certKeyFileName;commonname=$CommonName;organizationname=$OrganizationName;countryname=$CountryName;statename=$StateName}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslcertreq -Payload $payload -Action create
    
        Write-Verbose "Downloading certificate request"
        $arguments = @{filelocation="/nsconfig/ssl"}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemfile -ResourceName $certReqFileName -Arguments $arguments
    
        if (-not [String]::IsNullOrEmpty($response.systemfile.filecontent)) {
            $certReqContentBase64 = $response.systemfile.filecontent
        } else {
            throw "Certificate request file content returned empty"
        }
        $certReqContent = [System.Convert]::FromBase64String($certReqContentBase64)
        $certReqContent | Set-Content $certReqFileFull -Encoding Byte
    
        Write-Verbose "Requesting certificate"
        certreq.exe -Submit -q -attrib "CertificateTemplate:webserver" -config $CAName $certReqFileFull $certFileFull
    
        if (-not $? -or $LASTEXITCODE -ne 0) {
            throw "certreq.exe failed to request certificate"
        }

        Write-Verbose "Uploading certificate"
        if (Test-Path $certFileFull) {
            $certContent = Get-Content $certFileFull -Encoding "Byte"
            $certContentBase64 = [System.Convert]::ToBase64String($certContent)

            $payload = @{filename=$certFileName;filecontent=$certContentBase64;filelocation="/nsconfig/ssl/";fileencoding="BASE64"}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemfile -Payload $payload -Action add
        } else {
            throw "Cert file '$certFileFull' not found."
        }

        Write-Verbose "Creating certificate request"
        Add-NSCertKeyPair -NSSession $NSSession -CertKeyName $fileName -CertPath $certFileName -KeyPath $certKeyFileName
    }
    finally {
        Write-Verbose "Cleaning up local temp files"
        Remove-Item -Path "$env:TEMP\$CommonName.*" -Force
    }

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Add-NSCertKeyPair {
    <#
    .SYNOPSIS
        Add SSL certificate and private key pair
    .DESCRIPTION
        Add SSL certificate and private key  pair
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER CertKeyName
        Name for the certificate and private-key pair
    .PARAMETER CertPath
        Path to the X509 certificate file that is used to form the certificate-key pair
    .PARAMETER KeyPath
        path to the private-key file that is used to form the certificate-key pair
    .PARAMETER CertKeyFormat
        Input format of the certificate and the private-key files, allowed values are "PEM" and "DER", default to "PEM"
    .PARAMETER Passcrypt
        Pass phrase used to encrypt the private-key. Required when adding an encrypted private-key in PEM format
    .EXAMPLE
        Add-NSCertKeyPair -NSSession $Session -CertKeyName "*.xd.local" -CertPath "/nsconfig/ssl/ns.cert" -KeyPath "/nsconfig/ssl/ns.key" -CertKeyFormat PEM -Passcrypt "luVJAUxtmUY="
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$CertKeyName,
        [Parameter(Mandatory=$true)] [string]$CertPath,
        [Parameter(Mandatory=$true)] [string]$KeyPath,
        [Parameter(Mandatory=$false)] [ValidateSet("PEM","DER")] [string]$CertKeyFormat="PEM",
        [Parameter(Mandatory=$false)] [string]$Passcrypt
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $payload = @{certkey=$CertKeyName;cert=$CertPath;key=$KeyPath;inform=$CertKeyFormat}
    if ($CertKeyFormat -eq "PEM" -and $Passcrypt) {
        $payload.Add("passcrypt",$Passcrypt)
    }
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslcertkey -Payload $payload -Action add 

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Add-NSServer {
    <#
    .SYNOPSIS
        Add a new server resource
    .DESCRIPTION
        Add a new server resource
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER Name
        Name of the server
    .PARAMETER IPAddress
        IPv4 or IPv6 address of the server
        If this is not provided then the server name is used as its IP address
    .EXAMPLE
        Add-NSServer -NSSession $Session -ServerName "myServer" -ServerIPAddress "10.108.151.3"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$false)] [string]$Name,
        [Parameter(Mandatory=$true)] [string]$IPAddress
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    if (-not $Name) {
        $Name = $IPAddress
    }

    Write-Verbose "Validating IP Address"
    $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
    if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj)) {
        throw "'$IPAddress' is an invalid IP address"
    }
    
    $ipv6Address = if ($IPAddressObj.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6) { "YES" } else { "NO" }
    $payload = @{name=$Name;ipaddress=$IPAddress;ipv6address=$ipv6Address}
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType server -Payload $payload -Action add 
   
    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Add-NSService {
    <#
    .SYNOPSIS
        Add a new service resource
    .DESCRIPTION
        Add a new service resource
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER Name
        Name for the service
    .PARAMETER ServerName
        Name of the server that hosts the service
    .PARAMETER ServerIPAddress
        IPv4 or IPv6 address of the server that hosts the service
        By providing this parameter, it attempts to create a server resource for you that's named the same as the IP address provided
    .PARAMETER Type
        Protocol in which data is exchanged with the service
    .PARAMETER Port
        Port number of the service
    .PARAMETER InsertClientIPHeader
        Before forwarding a request to the service, insert an HTTP header with the client's IPv4 or IPv6 address as its value
        Used if the server needs the client's IP address for security, accounting, or other purposes, and setting the Use Source IP parameter is not a viable option
    .PARAMETER ClientIPHeader
        Name for the HTTP header whose value must be set to the IP address of the client
        Used with the Client IP parameter
        If you set the Client IP parameter, and you do not specify a name for the header, the appliance uses the header name specified for the global Client IP Header parameter
        If the global Client IP Header parameter is not specified, the appliance inserts a header with the name "client-ip."
    .EXAMPLE
        Add-NSService -NSSession $Session -Name "Server1_Service" -ServerName "Server1" -ServerIPAddress "10.108.151.3" -Type "HTTP" -Port 80
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$Name,
        [Parameter(Mandatory=$true,ParameterSetName='By Name')] [string]$ServerName,
        [Parameter(Mandatory=$true,ParameterSetName='By Address')] [string]$ServerIPAddress,
        [Parameter(Mandatory=$true)] [ValidateSet(
        "HTTP","FTP","TCP","UDP","SSL","SSL_BRIDGE","SSL_TCP","DTLS","NNTP","RPCSVR","DNS","ADNS","SNMP","RTSP","DHCPRA",
        "ANY","SIP_UDP","DNS_TCP","ADNS_TCP","MYSQL","MSSQL","ORACLE","RADIUS","RDP","DIAMETER","SSL_DIAMETER","TFTP"
        )] [string]$Type,
        [Parameter(Mandatory=$true)] [ValidateRange(1,65535)] [int]$Port,
        [Parameter(Mandatory=$false)] [switch]$InsertClientIPHeader,
        [Parameter(Mandatory=$false)] [string]$ClientIPHeader
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
    $cip = if ($InsertClientIPHeader) { "ENABLED" } else { "DISABLED" }
    $payload = @{name=$Name;servicetype=$Type;port=$Port;cip=$cip}
    if ($ClientIPHeader) {
        $payload.Add("cipheader",$ClientIPHeader)
    }
    if ($PSCmdlet.ParameterSetName -eq 'By Name') {
        $payload.Add("servername",$ServerName)
    } elseif ($PSCmdlet.ParameterSetName -eq 'By Address') {
        Write-Verbose "Validating IP Address"
        $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
        if (-not [System.Net.IPAddress]::TryParse($ServerIPAddress,[ref]$IPAddressObj)) {
            throw "'$ServerIPAddress' is an invalid IP address"
        }
        $payload.Add("ip",$ServerIPAddress)
    }

    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType service -Payload $payload -Action add 
   
    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Add-NSLBMonitor {
    <#
    .SYNOPSIS
        Create LB StoreFront monitor resource
    .DESCRIPTION
        Create LB StoreFront monitor resource
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER Name
        Name for the monitor
    .PARAMETER Type
        Type of monitor that you want to create
    .PARAMETER ScriptName
        Path and name of the script to execute. The script must be available on the NetScaler appliance, in the /nsconfig/monitors/ directory
    .PARAMETER LRTM
        Calculate the least response times for bound services. If this parameter is not enabled, the appliance does not learn the response times of the bound services. Also used for LRTM load balancing
    .PARAMTER DestinationIPAddress
        IP address of the service to which to send probes. If the parameter is set to 0, the IP address of the server to which the monitor is bound is considered the destination IP address
    .PARAMETER StoreName
        Store Name. For monitors of type STOREFRONT, STORENAME is an optional argument defining storefront service store name. Applicable to STOREFRONT monitors
    .EXAMPLE
        Add-NSLBMonitor -NSSession $Session -Name "Server1_Monitor" -Type "HTTP"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$Name,
        [Parameter(Mandatory=$true)] [ValidateSet(
        "PING","TCP","HTTP","TCP-ECV","HTTP-ECV","UDP-ECV","DNS","FTP","LDNS-PING","LDNS-TCP","LDNS-DNS","RADIUS","USER","HTTP-INLINE","SIP-UDP","LOAD","FTP-EXTENDED",
        "SMTP","SNMP","NNTP","MYSQL","MYSQL-ECV","MSSQL-ECV","ORACLE-ECV","LDAP","POP3","CITRIX-XML-SERVICE","CITRIX-WEB-INTERFACE","DNS-TCP","RTSP","ARP","CITRIX-AG",
        "CITRIX-AAC-LOGINPAGE","CITRIX-AAC-LAS","CITRIX-XD-DDC","ND6","CITRIX-WI-EXTENDED","DIAMETER","RADIUS_ACCOUNTING","STOREFRONT","APPC","CITRIX-XNC-ECV","CITRIX-XDM"
        )] [string]$Type,
        [Parameter(Mandatory=$false)] [string]$ScriptName,
        [Parameter(Mandatory=$false)] [switch]$LRTM,
        [Parameter(Mandatory=$false)] [string]$DestinationIPAddress,
        [Parameter(Mandatory=$false)] [string]$StoreName
        
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $lrtmSetting = if ($LRTM) { "ENABLED" } else { "DISABLED" }
    $payload = @{
        monitorname = $Name
        type = $Type
        lrtm = $lrtmSetting
    }
    if (-not [string]::IsNullOrEmpty($ScriptName)) {
        $payload.Add("scriptname",$ScriptName)
    }
    if (-not [string]::IsNullOrEmpty($StoreName)) {
        $payload.Add("storename",$StoreName)
    }
    if (-not [string]::IsNullOrEmpty($DestinationIPAddress)) {        
        Write-Verbose "Validating IP Address"
        $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
        if (-not [System.Net.IPAddress]::TryParse($DestinationIPAddress,[ref]$IPAddressObj)) {
            throw "'$DestinationIPAddress' is an invalid IP address"
        }
        $payload.Add("destip",$DestinationIPAddress)
    }
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType lbmonitor -Payload $payload -Action add 

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Add-NSLBSFMonitor {
    <#
    .SYNOPSIS
        Create LB StoreFront monitor resource
    .DESCRIPTION
        Create LB StoreFront monitor resource
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER Name
        Name for the monitor
    .PARAMTER StoreFrontIPAddress
        IP address of the StoreFront server to which to send probes.
    .PARAMETER StoreName
        Name of StoreFront Store
    .EXAMPLE
        Add-NSLBSFMonitor -NSSession $Session -Name "MyStoreFrontMonitor" -StoreFrontIPAddress "1.2.3.4" -StoreName "StoreFrontStore"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$Name,
        [Parameter(Mandatory=$true)] [string]$StoreFrontIPAddress,
        [Parameter(Mandatory=$true)] [string]$StoreName
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    Add-NSLBMonitor -NSSession $NSSession -Name $Name -Type "STOREFRONT" -LRTM -DestinationIPAddress $StoreFrontIPAddress -StoreName $StoreName

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function New-NSServiceLBMonitorBinding {
    <#
    .SYNOPSIS
        Bind monitor to service
    .DESCRIPTION
        Bind monitor to service
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER ServiceName
        Name of the service to which to bind monitor
    .PARAMETER MonitorName
        The monitor name
    .EXAMPLE
        New-NSServiceLBMonitorBinding -NSSession $Session -ServiceName "Server1_Service" -MonitorName "Server1_Monitor"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$ServiceName,
        [Parameter(Mandatory=$true)] [string]$MonitorName
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $payload = @{name=$ServiceName;monitor_name=$MonitorName}
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType service_lbmonitor_binding -Payload $payload -Action add 

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Add-NSLBVServer {
    <#
    .SYNOPSIS
        Add a new LB virtual server
    .DESCRIPTION
        Add a new LB virtual server
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER Name
        Name of the virtual server
    .PARAMETER IPAddress
        IPv4 or IPv6 address to assign to the virtual server
        Usually a public IP address. User devices send connection requests to this IP address
    .PARAMETER ServiceType
        Protocol used by the service (also called the service type)
    .PARAMETER Port
        Port number for the virtual server
    .PARAMETER PersistenceType
        Type of persistence for the virtual server
    .EXAMPLE
        Add-NSLBVServer -NSSession $Session -Name "myLBVirtualServer" -IPAddress "10.108.151.3" -ServiceType "SSL" -Port 443 -PersistenceType "SOURCEIP"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$Name,
        [Parameter(Mandatory=$true)] [string]$IPAddress,
        [Parameter(Mandatory=$false)] [ValidateSet(
        "HTTP","FTP","TCP","UDP","SSL","SSL_BRIDGE","SSL_TCP","DTLS","NNTP","DNS","DHCPRA","ANY","SIP_UDP","DNS_TCP",
        "RTSP","PUSH","SSL_PUSH","RADIUS","RDP","MYSQL","MSSQL","DIAMETER","SSL_DIAMETER","TFTP","ORACLE"
        )] [string]$ServiceType="SSL",
        [Parameter(Mandatory=$false)] [ValidateRange(1,65535)] [int]$Port=443,
        [Parameter(Mandatory=$false)] [ValidateSet(
        "SOURCEIP","COOKIEINSERT","SSLSESSION","RULE","URLPASSIVE","CUSTOMSERVERID","DESTIP","SRCIPDESTIP","CALLID","RTSPSID","DIAMETER","NONE"
        )] [string]$PersistenceType="SOURCEIP"
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    Write-Verbose "Validating IP Address"
    $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
    if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj)) {
        throw "'$IPAddress' is an invalid IP address"
    }

    $payload = @{name=$Name;ipv46=$IPAddress;servicetype=$ServiceType;port=$Port;persistencetype=$PersistenceType}
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType lbvserver -Payload $payload -Action add 
   
    Write-Verbose "$($MyInvocation.MyCommand): Exit"

}

function New-NSLBVServerServiceBinding {
    <#
    .SYNOPSIS
        Bind service to VPN virtual server
    .DESCRIPTION
        Bind service to VPN virtual server
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER VirtualServerName
        Name of the virtual server
    .PARAMETER ServiceName
        Service to bind to the virtual server
    .EXAMPLE
        New-NSLBVServerServiceBinding -NSSession $Session -VirtualServerName "myLBVirtualServer" -ServiceName "Server1_Service"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$VirtualServerName,
        [Parameter(Mandatory=$true)] [string]$ServiceName
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $payload = @{name=$VirtualServerName;servicename=$ServiceName}
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType lbvserver_service_binding -Payload $payload -Action add 

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function New-NSSSLVServerCertKeyBinding {
    <#
    .SYNOPSIS
        Bind a SSL certificate-key pair to a virtual server
    .DESCRIPTION
        Bind a SSL certificate-key pair to a virtual server
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER CertKeyName
        Name of the certificate key pair
    .PARAMETER VirtualServerName
        Name of the virtual server
    .EXAMPLE
        New-NSVPNVServerSSLCertKeyBinding -NSSession $Session -CertKeyName "*.xd.local" -VServerName myvs -WebSession $Session
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$CertKeyName,
        [Parameter(Mandatory=$true)] [string]$VirtualServerName
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $payload =  @{certkeyname=$CertKeyName;vservername=$VirtualServerName}
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType sslvserver_sslcertkey_binding -Payload $payload -Action add 

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

#endregion


#region Part 4

function Add-NSAuthLDAPAction {
    <#
    .SYNOPSIS
        Add a new NetScaler LDAP action
    .DESCRIPTION
        Add a new NetScaler LDAP action
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER LDAPActionName
        Name of the LDAP action
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
    .EXAMPLE
        Add-NSAuthLDAPAction -NSSession $Session -LDAPActionName "10.108.151.1_LDAP" -LDAPServerIP 10.8.115.245 -LDAPBaseDN "dc=xd,dc=local" -LDAPBindDN "administrator@xd.local" -LDAPBindDNPassword "passw0rd"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$LDAPActionName,
        [Parameter(Mandatory=$true)] [string]$LDAPServerIP,
        [Parameter(Mandatory=$true)] [string]$LDAPBaseDN,
        [Parameter(Mandatory=$true)] [string]$LDAPBindDN,
        [Parameter(Mandatory=$true)] [string]$LDAPBindDNPassword,
        [Parameter(Mandatory=$false)] [string]$LDAPLoginName="sAMAccountName"
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $payload =  @{name=$LDAPActionName;serverip=$LDAPServerIP;ldapbase=$LDAPBaseDN;ldapbinddn=$LDAPBindDN;ldapbinddnpassword=$LDAPBindDNPassword;ldaploginname=$LDAPLoginName}
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType authenticationldapaction -Payload $payload -Action add 

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Add-NSAuthLDAPPolicy {
    <#
    .SYNOPSIS
        Add a new NetScaler LDAP policy
    .DESCRIPTION
        Add a new NetScaler LDAP policy
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER LDAPActionName
        Name of the LDAP action to perform if the policy matches.
    .PARAMETER LDAPPolicyName
        Name of the LDAP policy
    .PARAMETER LDAPRuleExpression
        Name of the NetScaler named rule, or a default syntax expression, that the policy uses to determine whether to attempt to authenticate the user with the LDAP server.
    .EXAMPLE
        Add-NSAuthLDAPPolicy -NSSession $Session -LDAPActionName "10.8.115.245_LDAP" -LDAPPolicyName "10.8.115.245_LDAP_pol" -LDAPRuleExpression NS_TRUE
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$LDAPActionName,
        [Parameter(Mandatory=$true)] [string]$LDAPPolicyName,
        [Parameter(Mandatory=$false)] [string]$LDAPRuleExpression="ns_true"
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $payload = @{reqaction=$LDAPActionName;name=$LDAPPolicyName;rule=$LDAPRuleExpression}
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType authenticationldappolicy -Payload $payload -Action add 

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Add-NSVPNVServer {
    <#
    .SYNOPSIS
        Add a new VPN virtual server
    .DESCRIPTION
        Add a new VPN virtual server
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER Name
        Name of the virtual server
    .PARAMETER IPAddress
        IPv4 or IPv6 address to assign to the virtual server
        Usually a public IP address. User devices send connection requests to this IP address
    .PARAMETER Port
        Port number for the virtual server
    .PARAMETER ICAOnly
        User can log on in basic mode only, through either Citrix Receiver or a browser. Users are not allowed to connect by using the Access Gateway Plug-in
    .EXAMPLE
        Add-NSVPNVServer -NSSession $Session -Name "myVPNVirtualServer" -IPAddress "10.108.151.3" -Port 443 -ICAOnly
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$Name,
        [Parameter(Mandatory=$true)] [string]$IPAddress,
        [Parameter(Mandatory=$false)] [ValidateRange(1,65535)] [int]$Port=443,
        [Parameter(Mandatory=$false)] [switch]$ICAOnly=$true
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    Write-Verbose "Validating IP Address"
    $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
    if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj)) {
        throw "'$IPAddress' is an invalid IP address"
    }

    $ica = if ($ICAOnly) { "ON" } else { "OFF" }
    $payload = @{name=$Name;ipv46=$IPAddress;port=$Port;icaonly=$ica;servicetype="SSL"}
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType vpnvserver -Payload $payload -Action add 
   
    Write-Verbose "$($MyInvocation.MyCommand): Exit"

}

function New-NSVPNVServerAuthLDAPPolicyBinding {
    <#
    .SYNOPSIS
        Bind authentication LDAP policy to VPN virtual server
    .DESCRIPTION
        Bind authentication LDAP policy to VPN virtual server
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER VirtualServerName
        Name of the VPN virtual server
    .PARAMETER LDAPPolicyName
        The name of the policy to be bound to the vpn vserver
    .EXAMPLE
        New-NSVPNVServerAuthLDAPPolicyBinding -NSSession $Session -VirtualServerName "myVPNVirtualServer" -LDAPPolicyName "10.108.151.1_LDAP_pol"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$VirtualServerName,
        [Parameter(Mandatory=$true)] [string]$LDAPPolicyName
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $payload = @{name=$VirtualServerName;policy=$LDAPPolicyName}
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType vpnvserver_authenticationldappolicy_binding -Payload $payload -Action add 

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Add-NSVPNSessionAction {
    <#
    .SYNOPSIS
        Create VPN session action resource
    .DESCRIPTION
        Create VPN session action resource
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER SessionActionName
        Name for the session action
    .PARAMETER TransparentInterception
        Switch parameter. Allow access to network resources by using a single IP address and subnet mask or a range of IP addresses.
        When turned off,  sets the mode to proxy, in which you configure destination and source IP addresses and port numbers.
        If you are using the NetScale Gateway Plug-in for Windows, turn it on, in which the mode is set to transparent. 
        If you are using the NetScale Gateway Plug-in for Java, turn it off.
    .PARAMETER SplitTunnel
        Send, through the tunnel, traffic only for intranet applications that are defined in NetScaler Gateway. 
        Route all other traffic directly to the Internet.
        The OFF setting routes all traffic through Access Gateway. 
        With the REVERSE setting, intranet applications define the network traffic that is not intercepted.All network traffic directed to internal IP addresses bypasses the VPN tunnel, while other traffic goes through Access Gateway. 
        Reverse split tunneling can be used to log all non-local LAN traffic. 
        Possible values = ON, OFF, REVERSE
    .PARAMETER DefaultAuthorizationAction
        Specify the network resources that users have access to when they log on to the internal network. Acceptable vaules: "ALLOW","DENY"
        Default to "DENY", which deny access to all network resources. 
    .PARAMETER SSO,
        Set single sign-on (SSO) for the session. When the user accesses a server, the user's logon credentials are passed to the server for authentication.
        Acceptable values: "ON","OFF", default to 'ON"
    .PARAMETER IcaProxy
        Enable ICA proxy to configure secure Internet access to servers running Citrix XenApp or XenDesktop by using Citrix Receiver instead of the Access Gateway Plug-in.
    .PARAMETER NtDomain
        Single sign-on domain to use for single sign-on to applications in the internal network. 
        This setting can be overwritten by the domain that users specify at the time of logon or by the domain that the authentication server returns.
    .PARAMETER ClientlessVpnMode
        Enable clientless access for web, XenApp or XenDesktop, and FileShare resources without installing the Access Gateway Plug-in. 
        Available settings function as follows: * ON - Allow only clientless access. * OFF - Allow clientless access after users log on with the Access Gateway Plug-in. * DISABLED - Do not allow clientless access.
    .PARAMETER ClientChoices
        Provide users with multiple logon options. With client choices, users have the option of logging on by using the Access Gateway Plug-in for Windows, Access Gateway Plug-in for Java, the Web Interface, or clientless access from one location.
        Depending on how Access Gateway is configured, users are presented with up to three icons for logon choices. The most common are the Access Gateway Plug-in for Windows, Web Interface, and clientless access.
    .PARAMETER StoreFrontUrl,
        Web address for StoreFront to be used in this session for enumeration of resources from XenApp or XenDesktop.
    .PARAMETER WIHome
        Web address of the Web Interface server, such as http:///Citrix/XenApp, or Receiver for Web, which enumerates the virtualized resources, such as XenApp, XenDesktop, and cloud applications.
    .EXAMPLE
        Add-NSVPNSessionAction -NSSession $Session -SessionActionName AC_OS_10.108.151.1_S_ -NTDomain xd.local -WIHome "http://10.8.115.243/Citrix/StoreWeb" -StoreFrontUrl "http://10.8.115.243"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$SessionActionName,
        [Parameter(Mandatory=$false)] [ValidateSet("ON","OFF")] [string]$TransparentInterception="OFF",
        [Parameter(Mandatory=$false)] [ValidateSet("ON","OFF","REVERSE")] [string]$SplitTunnel="OFF",
        [Parameter(Mandatory=$false)] [ValidateSet("ALLOW","DENY")] [string]$DefaultAuthorizationAction="ALLOW",
        [Parameter(Mandatory=$false)] [ValidateSet("ON","OFF")] [string]$SSO="ON",
        [Parameter(Mandatory=$false)] [ValidateSet("ON","OFF")] [string]$IcaProxy="ON",
        [Parameter(Mandatory=$true)] [string]$NTDomain,
        [Parameter(Mandatory=$false)] [ValidateSet("ON","OFF","DISABLED")] [string]$ClientlessVpnMode="OFF",
        [Parameter(Mandatory=$false)] [ValidateSet("ON","OFF")] [string]$ClientChoices="OFF",
        [Parameter(Mandatory=$false)] [string]$StoreFrontUrl,
        [Parameter(Mandatory=$false)] [string]$WIHome="$StoreFrontUrl/Citrix/StoreWeb"
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $payload = @{
        name = $SessionActionName
        transparentinterception = $TransparentInterception
        splittunnel = $SplitTunnel
        defaultauthorizationaction = $DefaultAuthorizationAction
        SSO = $SSO
        icaproxy = $IcaProxy
        wihome = $WIHome
        clientchoices = $ClientChoices
        ntdomain = $NTDomain
        clientlessvpnmode=$ClientlessVpnMode
    }
    if (-not [string]::IsNullOrEmpty($StoreFrontUrl)) {
        $payload.Add("storefronturl",$StoreFrontUrl)
    }
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType vpnsessionaction -Payload $payload -Action add 

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function Add-NSVPNSessionPolicy {
    <#
    .SYNOPSIS
        Add VPN Session policy resources
    .DESCRIPTION
        Add VPN Session policy resources
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER SessionActionName
        Action to be applied by the new session policy if the rule criteria are met.
    .PARAMETER SessionPolicyName
        Name for the new session policy that is applied after the user logs on to Access Gateway.
    .PARAMETER SessionRuleExpression
        Expression, or name of a named expression, specifying the traffic that matches the policy.
        Can be written in either default or classic syntax. 
    .EXAMPLE
        Add-NSVPNSessionPolicy -NSSession $Session -SessionActionName "AC_OS_10.108.151.1_S_" -SessionPolicyName "PL_OS_10.108.151.1" -SessionRuleExpression "REQ.HTTP.HEADER User-Agent CONTAINS CitrixReceiver || REQ.HTTP.HEADER Referer NOTEXISTS"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$SessionActionName,
        [Parameter(Mandatory=$true)] [string]$SessionPolicyName,
        [Parameter(Mandatory=$true)] [string]$SessionRuleExpression
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $payload = @{name=$SessionPolicyName;action=$SessionActionName;rule=$SessionRuleExpression}
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType vpnsessionpolicy -Payload $payload -Action add 

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function New-NSVPNVServerSessionPolicyBinding {
    <#
    .SYNOPSIS
        Bind VPN session policy to VPN virtual server
    .DESCRIPTION
        Bind VPN session policy to VPN virtual server
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER VirtualServerName
        Name of the virtual server
    .PARAMETER SessionPolicyName
        The name of the policy, if any, bound to the vpn vserver
    .PARAMETER Priority
        The priority, if any, of the vpn vserver policy
    .EXAMPLE
        New-NSVPNVServerSessionPolicyBinding -NSSession $Session -VirtualServerName "myVPNVirtualServer" -SessionPolicyName "PL_OS_10.108.151.3" -Priority "100"
    .EXAMPLE    
        New-NSVPNVServerSessionPolicyBinding -NSSession $Session -VirtualServerName "myVPNVirtualServer" -SessionPolicyName "PL_WB_10.108.151.3" -Priority "100"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$VirtualServerName,
        [Parameter(Mandatory=$true)] [string]$SessionPolicyName,
        [Parameter(Mandatory=$false)] [string]$Priority="100"
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    $payload = @{name=$VirtualServerName;policy=$SessionPolicyName;priority=$Priority}
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType vpnvserver_vpnsessionpolicy_binding -Payload $payload -Action add 

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

function New-NSVPNVServerSTAServerBinding {
    <#
    .SYNOPSIS
        Bind STA server to VPN virtual server
    .DESCRIPTION
        Bind STA server to VPN virtual server
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER VirtualServerName
        Name of the virtual server.
    .PARAMETER STAServerURL
        Configured Secure Ticketing Authority (STA) server URL.
    .EXAMPLE
        New-NSVPNVServerSTAServerBinding -NSSession $Session -VirtualServerName "myVPNVirtualServer" -STAServerURL "http://10.108.156.7"
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$true)] [string]$VirtualServerName,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] [string]$STAServerURL
    )

    Begin {
        Write-Verbose "$($MyInvocation.MyCommand): Enter"
    }
    Process {
        $payload = @{name=$VirtualServerName;staserver=$STAServerURL}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType vpnvserver_staserver_binding -Payload $payload -Action add 
    }
    End {
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
}

function Set-NSSFStore {
    <#
    .SYNOPSIS
        Configure NetScaler to work with an existing StoreFront Receiver for Web site.
    .DESCRIPTION
        Configure NetScaler to work with an existing StoreFront Receiver for Web site. That involves creating session policies and actions and bind them to the virtual server
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER NSUserName
        UserName to access the NetScaler Managerment Console, default to nsroot
    .PARAMETER NSPassword
        Password to access the NetScaler Managerment Console, default to nsroot
    .PARAMETER VirtualServerName
        Virtual Server Name
    .PARAMETER VirtualServerIP
        IPAddress of Virtual Server
    .PARAMETER StoreFrontServerURL
        URL including the name or IPAddress of the StoreFront Server
    .PARAMETER STAServerURL
        STA Server URL, usually the XenApp & XenDesktop Controllers
    .PARAMETER SingleSignOnDomain
        Single SignOn Domain Name, the same domain is used to autheticate to NetScaler Gateway and pass on to StoreFront
    .PARAMETER ReceiverForWebPath
        Path to the Receiver For Web Website
    .EXAMPLE
        Set-NSSFStore -NSSession $Session -VirtualServerName "SkynetVS" -VirtualServerIPAddress "10.108.151.3" -StoreFrontServerURL "https://10.108.156.7" -STAServerURL "https://10.108.156.7" -SingleSignOnDomain xd.local
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession,
        [Parameter(Mandatory=$false)] [string]$NSUserName="nsroot", 
        [Parameter(Mandatory=$false)] [string]$NSPassword="nsroot",
        [Parameter(Mandatory=$true)] [string]$VirtualServerName,
        [Parameter(Mandatory=$true)] [string]$VirtualServerIPAddress,
        [Parameter(Mandatory=$true)] [string]$StoreFrontServerURL,
        [Parameter(Mandatory=$true)] [string[]]$STAServerURL,
        [Parameter(Mandatory=$true)] [string]$SingleSignOnDomain,
        [Parameter(Mandatory=$false)] [string]$ReceiverForWebPath="/Citrix/StoreWeb"
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    Add-NSVPNSessionAction -NSSession $NSSession -SessionActionName "AC_OS_$($VirtualServerIPAddress)_S_" -TransparentInterception "OFF" -SplitTunnel "OFF" `
    -DefaultAuthorizationAction "ALLOW" -SSO "ON" -IcaProxy "ON" -NTDomain $SingleSignOnDomain -ClientlessVpnMode "OFF" -ClientChoices "OFF" `
    -WIHome "$($StoreFrontServerURL.TrimEnd('/'))/$($ReceiverForWebPath.Trim('/'))" -StoreFrontUrl "$($StoreFrontServerURL.TrimEnd('/'))"

    Add-NSVPNSessionAction -NSSession $NSSession -SessionActionName "AC_WB_$($VirtualServerIPAddress)_S_" -TransparentInterception "OFF" -SplitTunnel "OFF" `
    -DefaultAuthorizationAction "ALLOW" -SSO "ON" -IcaProxy "ON" -NTDomain $SingleSignOnDomain -ClientlessVpnMode "OFF" -ClientChoices "OFF" `
    -WIHome "$($StoreFrontServerURL.TrimEnd('/'))/$($ReceiverForWebPath.Trim('/'))"

    Add-NSVPNSessionPolicy -NSSession $NSSession -SessionActionName "AC_OS_$($VirtualServerIPAddress)_S_" -SessionPolicyName "PL_OS_$($VirtualServerIPAddress)" `
    -SessionRuleExpression "REQ.HTTP.HEADER User-Agent CONTAINS CitrixReceiver || REQ.HTTP.HEADER Referer NOTEXISTS"

    Add-NSVPNSessionPolicy -NSSession $NSSession -SessionActionName "AC_WB_$($VirtualServerIPAddress)_S_" -SessionPolicyName "PL_WB_$($VirtualServerIPAddress)" `
    -SessionRuleExpression "REQ.HTTP.HEADER User-Agent NOTCONTAINS CitrixReceiver && REQ.HTTP.HEADER Referer EXISTS"

    New-NSVPNVServerSessionPolicyBinding -NSSession $NSSession -VirtualServerName $VirtualServerName -SessionPolicyName "PL_OS_$($VirtualServerIPAddress)" -Priority 100
    New-NSVPNVServerSessionPolicyBinding -NSSession $NSSession -VirtualServerName $VirtualServerName -SessionPolicyName "PL_WB_$($VirtualServerIPAddress)" -Priority 100

    $STAServerURL | New-NSVPNVServerSTAServerBinding -NSSession $NSSession -VirtualServerName $VirtualServerName

    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}

#endregion


#region Part 5

function New-NSHighAvailabilityPair {
    <#
    .SYNOPSIS
        Configures a new high availability pair
    .DESCRIPTION
        Configures a new high availability pair
        This also means that the configuration on the primary node is propagated and synchronized with the secondary node
    .PARAMETER PrimaryNSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER SecondaryNSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER SaveAfterSync
        Specify to save the NetScaler appliance configuration (including the HA changes) after creating and synchronizing the HA pair
    .PARAMETER InitialSyncTimeout
        Time in seconds to wait for synchronization to occur until timing out. This only applies when specifying SaveAfterSync
    .PARAMETER PeerNodeId
        Node ID to use for the peer node. This is normally kept as 1
    .EXAMPLE
        New-NSHighAvailabilityPair -PrimaryNSSession $PrimarySession -SecondaryNSSession $SecondarySession
    .NOTES
        Copyright (c) Citrix Systems, Inc. All rights reserved.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$PrimaryNSSession,
        [Parameter(Mandatory=$true)] [PSObject]$SecondaryNSSession,
        [Parameter(Mandatory=$false)] [switch]$SaveAfterSync,
        [Parameter(Mandatory=$false)] [int]$InitialSyncTimeout=900,
        [Parameter(Mandatory=$false)] [int]$PeerNodeId=1
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
    #GETTING MANAGEMENT ADDRESS
    Write-Verbose "Getting management IP address from '$($PrimaryNSSession.Endpoint)'"
    $response = Invoke-NSNitroRestApi -NSSession $PrimaryNSSession -OperationMethod GET -ResourceType nsconfig
    $primaryNSIP = $response.nsconfig.ipaddress

    Write-Verbose "Getting management IP address from '$($SecondaryNSSession.Endpoint)'"
    $response = Invoke-NSNitroRestApi -NSSession $SecondaryNSSession -OperationMethod GET -ResourceType nsconfig
    $secondaryNSIP = $response.nsconfig.ipaddress
    
    #FORCE THE NODES TO PRIMARY AND SECONDARY
    Write-Verbose "Setting '$($PrimaryNSSession.Endpoint)' to STAYPRIMARY"
    $payload = @{id=0;hastatus="STAYPRIMARY"}
    $response = Invoke-NSNitroRestApi -NSSession $PrimaryNSSession -OperationMethod PUT -ResourceType hanode -Payload $payload -Action update
    Write-Verbose "Setting '$($SecondaryNSSession.Endpoint)' to STAYSECONDARY"
    $payload = @{id=0;hastatus="STAYSECONDARY"}
    $response = Invoke-NSNitroRestApi -NSSession $SecondaryNSSession -OperationMethod PUT -ResourceType hanode -Payload $payload -Action update

    #ADD ALL OTHER NODES ON EACH NETSCALER 
    Write-Verbose "Adding node $PeerNodeId for '$($SecondaryNSSession.Endpoint)' on '$($PrimaryNSSession.Endpoint)'"
    $payload = @{id=$PeerNodeId;ipaddress=$secondaryNSIP}
    $response = Invoke-NSNitroRestApi -NSSession $PrimaryNSSession -OperationMethod POST -ResourceType hanode -Payload $payload -Action add
    Write-Verbose "Adding node $PeerNodeId for '$($PrimaryNSSession.Endpoint)' on '$($SecondaryNSSession.Endpoint)'"
    $payload = @{id=$PeerNodeId;ipaddress=$primaryNSIP}
    $response = Invoke-NSNitroRestApi -NSSession $SecondaryNSSession -OperationMethod POST -ResourceType hanode -Payload $payload -Action add

    #ENABLE NODES, FIRST ON SECONDARY AND FINALLY ON PRIMARY
    Write-Verbose "Setting '$($SecondaryNSSession.Endpoint)' to ENABLED"
    $payload = @{id=0;hastatus="ENABLED"}
    $response = Invoke-NSNitroRestApi -NSSession $SecondaryNSSession -OperationMethod PUT -ResourceType hanode -Payload $payload -Action update
    Write-Verbose "Setting '$($PrimaryNSSession.Endpoint)' to ENABLED"
    $payload = @{id=0;hastatus="ENABLED"}
    $response = Invoke-NSNitroRestApi -NSSession $PrimaryNSSession -OperationMethod PUT -ResourceType hanode -Payload $payload -Action update
    

    if ($SaveAfterSync) {
        $canWait = $true
        $waitStart = Get-Date
        while ($canWait) {
            Write-Verbose "Waiting for synchronization to complete..."
            Start-Sleep -Seconds 5
            $validation = Invoke-NSNitroRestApi -NSSession $PrimaryNSSession -OperationMethod GET -ResourceType hanode
            $secondaryNode = $validation.hanode | where { $_.id -eq "$PeerNodeId" }
            if ($($(Get-Date) - $waitStart).TotalSeconds -gt $InitialSyncTimeout) {
                $canWait = $false
            } elseif ($secondaryNode.hasync -eq "IN PROGRESS" -or $secondaryNode.hasync -eq "ENABLED") {
                Write-Verbose "Synchronization not done yet."
                continue
            } elseif ($secondaryNode.hasync -eq "SUCCESS") {
                Write-Verbose "Synchronization succesful. Saving configuration on both NetScaler appliances..."
                Save-NSConfig -NSSession $PrimaryNSSession
                Save-NSConfig -NSSession $SecondaryNSSession
                break
            } else {
                throw "Unexpected sync status '$($secondaryNode.hasync)'"
            }
        }

        if (-not $canWait) {
            throw "Timeout expired. Unable to save NetScaler appliance configuration because sync took too long."
        }
    }

    Write-Verbose "$($MyInvocation.MyCommand): Exit"

}

#endregion