<# 
.SYNOPSIS
    This module file contains NetScaler Configuration functions that extend the original Citrix NITRO Module.
.DESCRIPTION
    This module file contains NetScaler Configuration functions that extend the original Citrix NITRO Module.
.NOTES
    Copyright (c) cognition IT. All rights reserved.
#>
# Sample code
# Created with help from the original Citrix PowerShell Module, 
#downloadable at https://www.citrix.com/blogs/2014/10/16/scripting-automating-netscaler-configurations-using-nitro-rest-api-and-powershell-part-5/

# Enable default switches, like Verbose & Debug for script call
[CmdletBinding()]
# Declaring script parameters
Param()

#Requires -Version 3
Set-StrictMode -Version Latest

#region My Functions (and the original and updated Citrix functions)

#region REST API functions
    # Define default URL protocol to https, which can be changed by calling Set-Protocol function
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    $Script:NSURLProtocol = "https"

    # Copied from Citrix's Module to ensure correct scoping of variables and functions
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

        Write-Verbose "NSURLProtocol set to $Script:NSURLProtocol"
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }

    # Copied from Citrix's Module to ensure correct scoping of variables and functions
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

    # Copied from Citrix's Module to ensure correct scoping of variables and functions
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

    # Copied from Citrix's Module to ensure correct scoping of variables and functions
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

    # Invoke-NSNitroRestApi is UPDATED (provided by Citrix)
    # [adjusted for beter DELETE function support]
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
            Invoke-NSNitroRestApi -NSSession $Session -OperationMethod POST -ResourceType dnsnameserver -Payload $payload 
        .OUTPUTS
            Only when the OperationMethod is GET:
            PSCustomObject that represents the JSON response content. This object can be manipulated using the ConvertTo-Json Cmdlet.
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
            Copyright (c) cognition IT. All rights reserved.
            20160117: Adjusted to ensure DELETE methods can produce output as well as use the Arguments parameter
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession, 
            [Parameter(Mandatory=$true)] [ValidateSet("DELETE","GET","POST","PUT")] [string]$OperationMethod,
            [Parameter(Mandatory=$true)] [string]$ResourceType,
            [Parameter(Mandatory=$false)] [string]$ResourceName, 
            [Parameter(Mandatory=$false)] [string]$Action,
            [Parameter(Mandatory=$false)] [ValidateScript({(($OperationMethod -eq "GET") -or ($OperationMethod -eq "DELETE"))})] [hashtable]$Arguments=@{},
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
        if ($OperationMethod -eq "DELETE") {
            if ($Arguments.Count -gt 0) {
                Write-Verbose "Arguments found for DELETE"
                $uri += "?args="
                $argsList = @()
                foreach ($arg in $Arguments.GetEnumerator()) {
                    Write-verbose ("Adding " + $arg.Name + " to the list")
                    $argsList += "$($arg.Name):$([System.Uri]::EscapeDataString($arg.Value))"
                }
                $uri += $argsList -join ','
            }

        }
        Write-Verbose "URI: $uri"

        if ($OperationMethod -ne "GET") {
            Write-Verbose "Building Payload"
            $warning = if ($GetWarning) { "YES" } else { "NO" }
            $hashtablePayload = @{}
            $hashtablePayload."params" = @{"warning"=$warning;"onerror"=$OnErrorAction;<#"action"=$Action#>}
            $hashtablePayload.$ResourceType = $Payload
            #In recent versions of powershell the max value for the depth on convertto-json is 100
            #int::maxvalue returned 2147483647 and the max value it can accept is 100.
            $jsonPayload = ConvertTo-Json $hashtablePayload -Depth 100

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

            Write-Verbose $restParams
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

        if (($OperationMethod -eq "GET") -or ($OperationMethod -eq "DELETE"))  {
            return $response
        }
    }

#endregion

#region First Time setup
    # Set-NSHostName is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    # Updated 20160809: Removed action parameter from Invoke-NSNitroRestApi call
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
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType nshostname -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }

    function Get-NSHostName {
        <#
        .SYNOPSIS
            Get NetScaler Appliance Hostname
        .DESCRIPTION
            Get NetScaler Appliance Hostname
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
             Get-NSHostName -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nshostname -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['nshostname'])
        {
            return $response.nshostname.hostname
        }
        else
        {
            return $null
        }
    }
#endregion

#region System
    # Restart-NSAppliance is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
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

    # NOTE: Shutdown cannot be performed from the configuration utility
    # { "errorcode": 340, "message": "Not super-user", "severity": "ERROR" }
    function Stop-NSAppliance {
    <#
        .SYNOPSIS
            Shutdown NetScaler Appliance
        .DESCRIPTION
            Shutdown NetScaler Appliance
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Shutdown-NSAppliance -NSSession $Session 
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{}
        #$payload.Add("shutdown","")

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType shutdown -Payload $payload -Action shutdown -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }

    function New-SystemBackup {
        <#
        .SYNOPSIS
            Backup NetScaler Appliance
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
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Filename,
            [Parameter(Mandatory=$true)][ValidateSet("Full","Basic")] [string]$Level="Basic",
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Comment
        )
        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload=@{level=$Level}
        if ($Filename) {$payload.Add("filename",$Filename)}
    
        If (!([string]::IsNullOrEmpty($Comment))) {$payload.Add("comment",$Comment)}

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systembackup -Payload $payload -Action create


        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Get-SystemBackup {
        <#
        .SYNOPSIS
            Backup NetScaler Appliance
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
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )
        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systembackup -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        return $response.systembackup

    }

    function Restore-System {}

    #region DONE System - Licenses

    # Send-NSLicenseViaPSCP is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
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
    # Send-NSLicense is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    function Send-NSLicense {    
    # Updated 20160912: Removed Action parameter to avoid errors
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
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemfile -Payload $payload 
        } 
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }   
    }

    function Get-NSLicenseInfo {
        <#
        .SYNOPSIS
            Retrieve the NetScaler License information
        .DESCRIPTION
            Retrieve the NetScaler License information
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Get-NSLicenseInfo -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nslicense -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        return $response.nslicense
    }

    #endregion

    #region DONE System - Settings

    # Enable-NSMode is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
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
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsmode -Payload $payload -Action enable -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }

    function Disable-NSMode {
        <#
        .SYNOPSIS
            Disable NetScaler appliance mode(s)
        .DESCRIPTION
            Disable one or more NetScaler appliance mode(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Mode
            Mode(s) to be disabled. This can be passed as multiple modes (comma or space separated).
        .EXAMPLE
            Disable-NSMode -NSSession $Session -Mode "usnip"
        .EXAMPLE
            Disable-NSMode -NSSession $Session -Mode "usnip","mbf"
        .EXAMPLE
            Disable-NSMode -NSSession $Session -Mode "usnip mbf"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string[]]$Mode
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $modeParsed = $Mode.Trim().ToUpper() -join ' '

        $payload = @{mode=$modeParsed}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsmode -Payload $payload -Action disable -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Get-NSMode {
        <#
        .SYNOPSIS
            Get (all) NetScaler appliance mode(s)
        .DESCRIPTION
            Get one or more NetScaler appliance mode(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Mode
            Mode to be retrieved.
        .EXAMPLE
            Get-NSMode -NSSession $Session -Mode "wl"
        .EXAMPLE
            Get-NSMode -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string[]]$Mode
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        If ($Mode) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsmode -ResourceName $Mode -Verbose:$VerbosePreference
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsmode -Verbose:$VerbosePreference
        }

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['nsmode'])
        {
            return $response.nsmode
        }
        else
        {
            return $null
        }
    }

    # Enable-NSFeature is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
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
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsfeature -Payload $payload -Action enable -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }

    function Disable-NSFeature {
        <#
        .SYNOPSIS
            Disable NetScaler appliance feature(s)
        .DESCRIPTION
            Disable one or more NetScaler appliance feature(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Feature
            Feature(s) to be disabled. This can be passed as multiple features (comma or space separated).
        .EXAMPLE
            Disable-NSFeature -NSSession $Session -Feature "sslvpn"
        .EXAMPLE
            Disable-NSFeature -NSSession $Session -Feature "sslvpn","lb"
        .EXAMPLE
            Disable-NSFeature -NSSession $Session -Feature "sslvpn lb"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string[]]$Feature
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $featureParsed = $Feature.Trim().ToUpper() -join ' '

        $payload = @{feature=$featureParsed}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsfeature -Payload $payload -Action disable -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Get-NSFeature {
        <#
        .SYNOPSIS
            Get (all) NetScaler appliance feature(s)
        .DESCRIPTION
            Get one or more NetScaler appliance feature(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Feature
            Feature to be retrieved.
        .EXAMPLE
            Get-NSFeature -NSSession $Session -Feature "sslvpn"
        .EXAMPLE
            Get-NSFeature -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string[]]$Feature
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        If ($Feature) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsfeature -ResourceName $Feature -Verbose:$VerbosePreference
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsfeature -Verbose:$VerbosePreference
        }

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['nsfeature'])
        {
            return $response.nsfeature
        }
        else
        {
            return $null
        }
    }

    # Set-NSTimeZone is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    # Updated 20160809: Removed Action parameter from Invoke-NSNitroRestApi call
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
        $Job = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType nsconfig -Payload $payload 

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    # Import-NSTimeZones is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
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

    function Get-NSTimeZone {
        <#
        .SYNOPSIS
            Retrieve Set NetScaler Appliance Timezone
        .DESCRIPTION
            Retrieve NetScaler Appliance Timezone
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
             Get-NSTimeZone -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )
    
        Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsconfig -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['nsconfig'])
        {
            return $response.nsconfig.timezone
        }
        else
        {
            return $null
        }
    }

    function Enable-NSCEIP {
        <#
        .SYNOPSIS
            Enable the Citrix Customer Experience Improvement Program
        .DESCRIPTION
            Enable the Citrix Customer Experience Improvement Program
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Enable-NSCEIP -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            <#
            update

            URL:http://<NSIP>/nitro/v1/config/
            HTTP Method:PUT
            Request Payload:JSON
            {
            "params": {
                  "warning":<String_value>,
                  "onerror":<String_value>"
            },
            sessionid":"##sessionid",
            "systemparameter":{
                  "rbaonresponse":<String_value>,
                  "promptstring":<String_value>,
                  "natpcbforceflushlimit":<Double_value>,
                  "natpcbrstontimeout":<String_value>,
                  "timeout":<Double_value>,
                  "localauth":<String_value>,
                  "minpasswordlen":<Double_value>,
                  "strongpassword":<String_value>,
                  "restrictedtimeout":<String_value>,
                  "fipsusermode":<String_value>,
                  "doppler":<String_value>,
                  "googleanalytics":<String_value>,
            }}

            Response Payload:JSON

            { "errorcode": 0, "message": "Done", "severity": <String_value> }

            doppler<String>     Enable or disable Doppler. Default value: DISABLED Possible values = ENABLED, DISABLED
            #>
            $payload = @{}
        }
        Process {
            $payload.Add("doppler","ENABLED")        
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType systemparameter -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Disable-NSCEIP {
        <#
        .SYNOPSIS
            Disable the Citrix Customer Experience Improvement Program
        .DESCRIPTION
            Disable the Citrix Customer Experience Improvement Program
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Disable-NSCEIP -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            <#
            update

            URL:http://<NSIP>/nitro/v1/config/
            HTTP Method:PUT
            Request Payload:JSON
            {
            "params": {
                  "warning":<String_value>,
                  "onerror":<String_value>"
            },
            sessionid":"##sessionid",
            "systemparameter":{
                  "rbaonresponse":<String_value>,
                  "promptstring":<String_value>,
                  "natpcbforceflushlimit":<Double_value>,
                  "natpcbrstontimeout":<String_value>,
                  "timeout":<Double_value>,
                  "localauth":<String_value>,
                  "minpasswordlen":<Double_value>,
                  "strongpassword":<String_value>,
                  "restrictedtimeout":<String_value>,
                  "fipsusermode":<String_value>,
                  "doppler":<String_value>,
                  "googleanalytics":<String_value>,
            }}

            Response Payload:JSON

            { "errorcode": 0, "message": "Done", "severity": <String_value> }

            doppler<String>     Enable or disable Doppler. Default value: DISABLED Possible values = ENABLED, DISABLED
            #>
            $payload = @{}
        }
        Process {
            $payload.Add("doppler","DISABLED")        
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType systemparameter -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Get-NSCEIP {
        <#
        .SYNOPSIS
            Retrieve the Citrix Customer Experience Improvement Program status
        .DESCRIPTION
            Retrieve the Citrix Customer Experience Improvement Program status
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Get-NSCEIP -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            <#
            get (all)

            URL:http://<NSIP>/nitro/v1/config/systemparameter
            Query-parameters:
            HTTP Method:GET
            Response Payload:JSON
            { "errorcode": 0, "message": "Done", "severity": <String_value>, "systemparameter": [ {
                  "rbaonresponse":<String_value>,
                  "promptstring":<String_value>,
                  "natpcbforceflushlimit":<Double_value>,
                  "natpcbrstontimeout":<String_value>,
                  "timeout":<Double_value>,
                  "maxclient":<Double_value>,
                  "localauth":<String_value>,
                  "minpasswordlen":<Double_value>,
                  "strongpassword":<String_value>,
                  "restrictedtimeout":<String_value>,
                  "fipsusermode":<String_value>,
                  "doppler":<String_value>,
                  "googleanalytics":<String_value>
            }]}
            #>
            $payload = @{}
        }
        Process {
            $payload.Add("doppler","ENABLED")        
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemparameter -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['systemparameter'])
            {
                return $response.systemparameter.doppler
            }
            else
            {
                return $null
            }
        }
    }

    #endregion
    #region DONE System - Diagnostics

    # Save-NSConfig is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
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

    function Clear-NSConfig {
        <#
        .SYNOPSIS
            Clear the NetScaler Config File 
        .DESCRIPTION
            Clear the NetScaler Config File 
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Level
            Types of configurations to be cleared. Possible values = basic, extended, full
        .SWITCH Enforced
            Configurations will be cleared without prompting for confirmation.
        .EXAMPLE
            Clear-NSConfig -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        <# Reset NS configuration
        CLI: clear ns config [-force] <level>
        <level> = basic, extended or full

        NITRO:
        clear

        URL:http://<NSIP>/nitro/v1/config/

        HTTP Method:POST

        Request Payload:JSON

        object={
        "params":{
              "warning":<String_value>,
              "onerror":<String_value>,
              "action":"clear"
        },
        "sessionid":"##sessionid",
        "nsconfig":{
              "force":<Boolean_value>,
              "level":<String_value>,
        }}

        Response Payload:JSON

        { "errorcode": 0, "message": "Done", "severity": <String_value> }
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [ValidateSet("basic", "extended", "full")] [string]$Level="basic",
            [Parameter(Mandatory=$false)] [switch]$Enforced
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{}
        If ($Enforced) {
            $payload.Add("force",$true)
        }
        $payload.Add("level",$Level)

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsconfig -Payload $payload -Action "clear" -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }

    #endregion
    #region System - High Availability

    # New-NSHighAvailabilityPair is part of the Citrix NITRO Module

    #endregion
    #region DONE System - NTP Servers

    function Add-NSNTPServer {
        <#
        .SYNOPSIS
            Add a NetScaler NTP Server Configuration
        .DESCRIPTION
            Add a NetScaler NTP Server Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ServerIP
            IPv4 address of the NTP Server. Minimum length = 1
        .PARAMETER ServerName
            Fully qualified domain name of the NTP server.
        .PARAMETER MinPoll
            Minimum time after which the NTP server must poll the NTP messages. In seconds, expressed as a power of 2. Minimum value = 4. Maximum value = 17.
        .PARAMETER MaxPoll
            Maximum time after which the NTP server must poll the NTP messages. In seconds, expressed as a power of 2. Minimum value = 4. Maximum value = 17.
        .PARAMETER Key
            Key to use for encrypting authentication fields. All packets sent to and received from the server must include authentication fields encrypted by using this key. To require authentication for communication with the server, you must set either the value of this parameter or the autokey parameter. Minimum value = 1. Maximum value = 65534.
        .EXAMPLE
            Add-NSNTPServer -NSSession $Session -ServerIP "10.108.151.2" -MinPoll 5 -MaxPoll 10
        .EXAMPLE
            Add-NSNTPServer -NSSession $Session -ServerName "ntp.server.com"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true,ParameterSetName='Address')] [string]$ServerIP,
            [Parameter(Mandatory=$true,ParameterSetName='Name')] [string]$ServerName,
            [Parameter(Mandatory=$false)] [ValidateRange(4,17)] [int]$MinPoll,
            [Parameter(Mandatory=$false)] [ValidateRange(4,17)] [int]$MaxPoll,
            [Parameter(Mandatory=$false)] [ValidateRange(1,65534)] [int]$Key
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{}
        }
        Process {
            if ($PSCmdlet.ParameterSetName -eq 'Address') {
                Write-Verbose "Validating NTP Server IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($ServerIP,[ref]$IPAddressObj)) {
                    throw "'$ServerIP' is an invalid IP address"
                }
                $payload.Add("serverip",$ServerIP)
            } elseif ($PSCmdlet.ParameterSetName -eq 'Name') {
                $payload.Add("servername",$ServerName)
            }
            if ($MinPoll) {
                $payload.Add("minpoll",$MinPoll)
            }
            if ($MaxPoll) {
                $payload.Add("maxpoll",$MaxPoll)
            }
            if ($Key) {
                $payload.Add("key",$Key)
            }
            else {
                $payload.Add("autokey",$true)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType ntpserver -Payload $payload  -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Update-NSNTPServer {
        <#
        .SYNOPSIS
            Update a NetScaler NTP Server Configuration
        .DESCRIPTION
            Update a NetScaler NTP Server Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ServerIP
            IPv4 address of the NTP Server. Minimum length = 1
        .PARAMETER ServerName
            Fully qualified domain name of the NTP server.
        .PARAMETER MinPoll
            Minimum time after which the NTP server must poll the NTP messages. In seconds, expressed as a power of 2. Minimum value = 4. Maximum value = 17.
        .PARAMETER MaxPoll
            Maximum time after which the NTP server must poll the NTP messages. In seconds, expressed as a power of 2. Minimum value = 4. Maximum value = 17.
        .PARAMETER Key
            Key to use for encrypting authentication fields. All packets sent to and received from the server must include authentication fields encrypted by using this key. To require authentication for communication with the server, you must set either the value of this parameter or the autokey parameter. Minimum value = 1. Maximum value = 65534.
        .SWITCH Preferred
            Preferred NTP server. The NetScaler appliance chooses this NTP server for time synchronization among a set of correctly operating hosts. Default value: NO. Possible values = YES, NO
        .EXAMPLE
            Update-NSNTPServer -NSSession $Session -NTPServerIP "10.108.151.2" -MinPoll 5 -MaxPoll 10
        .EXAMPLE
            Update-NSNTPServer -NSSession $Session -NTPServerName "ntp.server.com" -Preferred        
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true,ParameterSetName='Address')] [string]$ServerIP,
            [Parameter(Mandatory=$true,ParameterSetName='Name')] [string]$ServerName,
            [Parameter(Mandatory=$false)] [ValidateRange(4,17)] [int]$MinPoll,
            [Parameter(Mandatory=$false)] [ValidateRange(4,17)] [int]$MaxPoll,
            [Parameter(Mandatory=$false)] [ValidateRange(1,65534)] [int]$Key,
            [Parameter(Mandatory=$false)] [switch]$Preferred
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{}
        }
        Process {
            $PreferredState = if ($Preferred) { "YES" } else { "NO" }
            $payload.Add("preferredntpserver",$PreferredState)        

            if ($PSCmdlet.ParameterSetName -eq 'Address') {
                Write-Verbose "Validating NTP Server IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($ServerIP,[ref]$IPAddressObj)) {
                    throw "'$ServerIP' is an invalid IP address"
                }
                $payload.Add("serverip",$ServerIP)
            } elseif ($PSCmdlet.ParameterSetName -eq 'Name') {
                $payload.Add("servername",$ServerName)
            }
            if ($MinPoll) {
                $payload.Add("minpoll",$MinPoll)
            }
            if ($MaxPoll) {
                $payload.Add("maxpoll",$MaxPoll)
            }
            if ($Key) {
                $payload.Add("key",$Key)
            }
            else {
                $payload.Add("autokey",$true)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType ntpserver -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Remove-NSNTPServer {
        <#
        .SYNOPSIS
            Delete a NetScaler NTP Server Configuration
        .DESCRIPTION
            Delete a NetScaler NTP Server Configuration
        .PARAMETER ServerName
            Fully qualified domain name or IPv4 address of the NTP server.
        .EXAMPLE
            Delete-NSNTPServer -NSSession $Session -ServerName "10.108.151.2"
        .EXAMPLE
            Delete-NSNTPServer -NSSession $Session -ServerName "ntp.server.com"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$ServerName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType ntpserver -ResourceName $ServerName -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Get-NSNTPServer {
        <#
        .SYNOPSIS
            Retrieve a NetScaler NTP Server Configuration
        .DESCRIPTION
            Retrieve a NetScaler NTP Server Configuration
        .PARAMETER ServerName
            Fully qualified domain name or IPv4 address of the NTP server.
        .EXAMPLE
            Get-NSNTPServer -NSSession $Session -ServerName "10.108.151.2"
        .EXAMPLE
            Get-NSNTPServer -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$ServerName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($ServerName){
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType ntpserver -ResourceName $ServerName -Verbose:$VerbosePreference
            }
            Else {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType ntpserver -Verbose:$VerbosePreference
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['ntpserver'])
            {
                return $response.ntpserver
            }
            else
            {
                return $null
            }
        }
    }

    function Enable-NSNTPSync {
        <#
        .SYNOPSIS
            Enable the NTP Synchronization
        .DESCRIPTION
            Enable the NTP Synchronization
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Enable-NSNTPSync -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType ntpsync -Payload $payload -Action enable -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Disable-NSNTPSync {
        <#
        .SYNOPSIS
            Disable the NTP Synchronization
        .DESCRIPTION
            Disable the NTP Synchronization
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Enable-NSNTPSync -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType ntpsync -Payload $payload -Action disable -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }

    function Get-NSNTPSync {
        <#
        .SYNOPSIS
            Retrieve the NTP Synchronization setting from the NetScaler Configuration
        .DESCRIPTION
            Retrieve the NTP Synchronization setting from the NetScaler Configuration
        .EXAMPLE
            Get-NSNTPSync -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType ntpsync -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['ntpsync'])
            {
                return $response.ntpsync
            }
            else
            {
                return $null
            }
        }
    }
    function Get-NSNTPStatus {
        <#
        .SYNOPSIS
            Retrieve the NTP status from the NetScaler Configuration
        .DESCRIPTION
            Retrieve the NTP status from the NetScaler Configuration
        .EXAMPLE
            Get-NSNTPStatus -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType ntpstatus -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['ntpstatus'])
            {
                return $response.ntpstatus
            }
            else
            {
                return $null
            }
        }
    }

    #endregion
    #region DONE System - User Administration

    function Add-NSSystemUser {
        <#
        .SYNOPSIS
            Add a system user resource to the NetScaler configuration
        .DESCRIPTION
            Add a system user resource to the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name for a user. Cannot be changed after the user is added. Minimum length = 1
        .PARAMETER Password
            Password for the system user. Can include any ASCII character. Minimum length = 1
        .SWITCH ExternalAuth
            Whether to use external authentication servers for the system user authentication or not. Default value: ENABLED. Possible values = ENABLED, DISABLED.
        .PARAMETER PromptString
            String to display at the command-line prompt. Minimum length = 1
        .PARAMETER Timeout
            CLI session inactivity timeout, in seconds. Default value is 900 seconds.
        .SWITCH Logging
            Users logging privilege. Default value: DISABLED. Possible values = ENABLED, DISABLED.
        .EXAMPLE
            Add-NSSystemUser -NSSession $Session -UserName user -Password password
        .EXAMPLE
            Add-NSSystemUser -NSSession $Session -UserName user -Password password -ExternalAuth -Timeout 300 -Logging
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$UserName,
            [Parameter(Mandatory=$true)] [string]$Password,
            [Parameter(Mandatory=$false)] [switch]$ExternalAuth,
            [Parameter(Mandatory=$false)] [string]$PromptString,
            [Parameter(Mandatory=$false)] [ValidateRange(0,100000000)][int]$Timeout=900,
            [Parameter(Mandatory=$false)] [switch]$Logging=$false
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $extauth = if ($ExternalAuth) { "ENABLED" } else { "DISABLED" }
        $userlogging = if ($Logging) { "ENABLED" } else { "DISABLED" }

        $payload = @{username=$UserName;password=$Password;externalauth=$extauth;logging=$userlogging}

        if ($Timeout) {
            $payload.Add("timeout",$Timeout)
        }

        if (-not [string]::IsNullOrEmpty($PromptString)) {
            $payload.Add("promptstring",$PromptString)
        }

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemuser -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Update-NSSystemUser {
        <#
        .SYNOPSIS
            Update a system user resource of the NetScaler configuration
        .DESCRIPTION
            Update a system user resource of the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name of the system user to update. Minimum length = 1
        .PARAMETER Password
            Password for the system user. Can include any ASCII character. Minimum length = 1
        .SWITCH ExternalAuth
            Whether to use external authentication servers for the system user authentication or not. Default value: ENABLED. Possible values = ENABLED, DISABLED.
        .PARAMETER PromptString
            String to display at the command-line prompt. Minimum length = 1
        .PARAMETER Timeout
            CLI session inactivity timeout, in seconds. Default value is 900 seconds.
        .SWITCH Logging
            Users logging privilege. Default value: DISABLED. Possible values = ENABLED, DISABLED.
        .EXAMPLE
            Update-NSSystemUser -NSSession $Session -UserName user -Password password
        .EXAMPLE
            Update-NSSystemUser -NSSession $Session -UserName user -Password password -ExternalAuth -Timeout 300 -Logging
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$UserName,
            [Parameter(Mandatory=$false)] [string]$Password,
            [Parameter(Mandatory=$false)] [switch]$ExternalAuth=$false,
            [Parameter(Mandatory=$false)] [string]$PromptString,
            [Parameter(Mandatory=$false)] [ValidateRange(0,100000000)][int]$Timeout=900,
            [Parameter(Mandatory=$false)] [switch]$Logging=$false
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $extauth = if ($ExternalAuth) { "ENABLED" } else { "DISABLED" }
        $userlogging = if ($Logging) { "ENABLED" } else { "DISABLED" }

        $payload = @{username=$UserName;externalauth=$extauth;logging=$userlogging}

        if ($Timeout) {
            $payload.Add("timeout",$Timeout)
        }

        if (-not [string]::IsNullOrEmpty($Password)) {
            $payload.Add("password",$Password)
        }
        if (-not [string]::IsNullOrEmpty($PromptString)) {
            $payload.Add("promptstring",$PromptString)
        }

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType systemuser -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Remove-NSSystemUser {
        <#
        .SYNOPSIS
            Delete a system user resource from the NetScaler configuration
        .DESCRIPTION
            Delete a system user resource from the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name of the system user to delete. Minimum length = 1
        .EXAMPLE
            Delete-NSSystemUser -NSSession $Session -UserName user
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$UserName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType systemuser -ResourceName $UserName -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Get-NSSystemUser {
        <#
        .SYNOPSIS
            Retrieve the system user resource(s) from the NetScaler configuration
        .DESCRIPTION
            Retrieve the system user resource(s) from the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name of the system user to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSystemUser -NSSession $Session -UserName user
        .EXAMPLE
            Get-NSSystemUser -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$UserName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{}

        If (-not [string]::IsNullOrEmpty($UserName)) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemuser -ResourceName $UserName -Verbose:$VerbosePreference
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemuser -Verbose:$VerbosePreference
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['systemuser'])
        {
            return $response.systemuser
        }
        else
        {
            return $null
        }
    }

    function New-NSSystemUserSystemCmdPolicyBinding {
        <#
        .SYNOPSIS
            Bind a system command policy to a given system user of the NetScaler Configuration
        .DESCRIPTION
            Bind a system command policy to a given system user of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name of the user to add the binding to. Minimum length = 1
        .PARAMETER PolicyName
            Name of the command policy that is binded to the group.
        .PARAMETER Priority
            The priority of the command policy
        .EXAMPLE
            Add-NSSystemUserSystemCmdPolicyBinding -NSSession $Session -UserName group -PolicyName commandpolicy
        .EXAMPLE
            Add-NSSystemUserSystemCmdPolicyBinding -NSSession $Session -UserName group -PolicyName commandpolicy -Priority 90
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$UserName,
            [Parameter(Mandatory=$true)] [string]$PolicyName,
            [Parameter(Mandatory=$false)] [int]$Priority
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $prio = if ($Priority) { $Priority } else { 100 }

        $payload = @{username=$UserName; policyname=$PolicyName; priority=$prio}

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemuser_systemcmdpolicy_binding -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Remove-NSSystemUserSystemCmdPolicyBinding {
        <#
        .SYNOPSIS
            Unbind a system command policy from a given system user of the NetScaler Configuration
        .DESCRIPTION
            Unbind a system command policy from a given system user of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name of the user to remove the binding from. Minimum length = 1
        .PARAMETER PolicyName
            Name of the command policy that is unbinded from the group.
        .EXAMPLE
            Remove-NSSystemUserSystemCmdPolicyBinding -NSSession $Session -UserName user -PolicyName commandpolicy
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$UserName,
            [Parameter(Mandatory=$true)] [string]$PolicyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $args = @{policyname=$PolicyName}

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType systemuser_systemcmdpolicy_binding -ResourceName $UserName -Arguments $args -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Get-NSSystemUserSystemCmdPolicyBinding {
        <#
        .SYNOPSIS
            Get the bound command policy(s) to a given system user of the NetScaler Configuration
        .DESCRIPTION
            Get the bound command policy(s) to a given system user of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name of the user to retrieve the binding from. Minimum length = 1
        .EXAMPLE
            Get-NSSystemUserSystemCmdPolicyBinding -NSSession $Session -UserName user -PolicyName commandpolicy
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$UserName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemuser_systemcmdpolicy_binding -ResourceName $UserName -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['systemuser_systemcmdpolicy_binding'])
        {
            return $response.systemuser_systemcmdpolicy_binding
        }
        else
        {
            return $null
        }
    }

    function Add-NSSystemGroup {
        <#
        .SYNOPSIS
            Add a system group resource to the NetScaler configuration
        .DESCRIPTION
            Add a system group resource to the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name for the group. Cannot be changed after the group is added. Minimum length = 1
        .PARAMETER PromptString
            String to display at the command-line prompt. Minimum length = 1
        .PARAMETER Timeout
            CLI session inactivity timeout, in seconds. Default value is 900 seconds.
        .EXAMPLE
            Add-NSSystemGroup -NSSession $Session -GroupName group
        .EXAMPLE
            Add-NSSystemGroup -NSSession $Session -GroupName group -PromptString grpstring -Timeout 300
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName,
            [Parameter(Mandatory=$false)] [string]$PromptString,
            [Parameter(Mandatory=$false)] [ValidateRange(0,100000000)][int]$Timeout=900
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{groupname=$GroupName}

        if ($Timeout) {
            $payload.Add("timeout",$Timeout)
        }

        if (-not [string]::IsNullOrEmpty($PromptString)) {
            $payload.Add("promptstring",$PromptString)
        }

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemgroup -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Update-NSSystemGroup {
        <#
        .SYNOPSIS
            Update a system group resource of the NetScaler configuration
        .DESCRIPTION
            Update a system group resource of the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to update. Minimum length = 1
        .PARAMETER PromptString
            String to display at the command-line prompt. Minimum length = 1
        .PARAMETER Timeout
            CLI session inactivity timeout, in seconds. Default value is 900 seconds.
        .EXAMPLE
            Update-NSSystemGroup -NSSession $Session -GroupName group -PromptString grpstring -Timeout 300
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName,
            [Parameter(Mandatory=$false)] [string]$PromptString,
            [Parameter(Mandatory=$false)] [ValidateRange(0,100000000)][int]$Timeout=900
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{groupname=$GroupName}

        if ($Timeout) {
            $payload.Add("timeout",$Timeout)
        }

        if (-not [string]::IsNullOrEmpty($PromptString)) {
            $payload.Add("promptstring",$PromptString)
        }

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType systemgroup -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Remove-NSSystemGroup {
        <#
        .SYNOPSIS
            Delete a system group resource from the NetScaler configuration
        .DESCRIPTION
            Delete a system group resource from the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to delete. Minimum length = 1
        .EXAMPLE
            Delete-NSSystemGroup -NSSession $Session -GroupName group
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType systemgroup -ResourceName $GroupName

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Get-NSSystemGroup {
        <#
        .SYNOPSIS
            Retrieve system group resource(s) from the NetScaler configuration
        .DESCRIPTION
            Retrieve system group resource(s) from the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSystemGroup -NSSession $Session -GroupName group
        .EXAMPLE
            Get-NSSystemGroup -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$GroupName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{}

        If (-not [string]::IsNullOrEmpty($GroupName)) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemgroup -ResourceName $GroupName
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemgroup
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['systemgroup'])
        {
            return $response.systemgroup
        }
        else
        {
            return $null
        }
    }

    function New-NSSystemGroupSystemUserBinding {
        <#
        .SYNOPSIS
            Bind a system user to a given system group of the NetScaler Configuration
        .DESCRIPTION
            Bind a system user to a given system group of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to add the binding to. Minimum length = 1
        .PARAMETER UserName
            Name of the command policy that is binded to the group.
        .EXAMPLE
            Add-NSSystemGroupSystemUserBinding -NSSession $Session -GroupName group -UserName commandpolicy
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName,
            [Parameter(Mandatory=$true)] [string]$UserName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{groupname=$GroupName; username=$UserName}

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemgroup_systemuser_binding -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Remove-NSSystemGroupSystemUserBinding {
        <#
        .SYNOPSIS
            Unbind a system user from a given system group of the NetScaler Configuration
        .DESCRIPTION
            Unbind a system user from a given system group of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to add the binding to. Minimum length = 1
        .PARAMETER PolicyName
            Name of the system user that is binded to the group.
        .EXAMPLE
            Remove-NSSystemGroupSystemUserBinding -NSSession $Session -GroupName group -UserName systemuser
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName,
            [Parameter(Mandatory=$true)] [string]$UserName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $args = @{username=$UserName}

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType systemgroup_systemuser_binding -ResourceName $GroupName -Arguments $args

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Get-NSSystemGroupSystemUserBinding {
        <#
        .SYNOPSIS
            Retrieve the binded system user(s) for a given system group of the NetScaler Configuration
        .DESCRIPTION
            Retrieve the binded system user(s) for a given system group of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSystemGroupSystemUserBinding -NSSession $Session -Group group
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{}

        If (-not [string]::IsNullOrEmpty($GroupName)) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemgroup_systemuser_binding -ResourceName $GroupName
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemgroup_systemuser_binding
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['systemgroup_systemuser_binding'])
        {
            return $response.systemgroup_systemuser_binding
        }
        else
        {
            return $null
        }
    }
    function Get-NSSystemUserSystemGroupBinding {
        <#
        .SYNOPSIS
            Retrieve the binded system group(s) for a given system user of the NetScaler Configuration
        .DESCRIPTION
            Retrieve the binded system group(s) for a given system user of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name of the user to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSystemUserSystemGroupBinding -NSSession $Session -Group group
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$UserName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{}

        If (-not [string]::IsNullOrEmpty($UserName)) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemuser_systemgroup_binding -ResourceName $UserName
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemuser_systemgroup_binding
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['systemuser_systemgroup_binding'])
        {
            return $response.systemuser_systemgroup_binding
        }
        else
        {
            return $null
        }
    }

    function New-NSSystemGroupSystemCmdPolicyBinding {
        <#
        .SYNOPSIS
            Bind a system command policy to a given system group of the NetScaler Configuration
        .DESCRIPTION
            Bind a system command policy to a given system group of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to add the binding to. Minimum length = 1
        .PARAMETER PolicyName
            Name of the command policy that is binded to the group.
        .PARAMETER Priority
            The priority of the command policy
        .EXAMPLE
            Add-NSSystemGroupSystemCmdPolicyBinding -NSSession $Session -GroupName group -PolicyName commandpolicy
        .EXAMPLE
            Add-NSSystemGroupSystemCmdPolicyBinding -NSSession $Session -GroupName group -PolicyName commandpolicy -Priority 90
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName,
            [Parameter(Mandatory=$true)] [string]$PolicyName,
            [Parameter(Mandatory=$false)] [int]$Priority
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $prio = if ($Priority) { $Priority } else { 100 }

        $payload = @{groupname=$GroupName; policyname=$PolicyName; priority=$prio}

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemgroup_systemcmdpolicy_binding -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Remove-NSSystemGroupSystemCmdPolicyBinding {
        <#
        .SYNOPSIS
            Unbind a system command policy to a given system group of the NetScaler Configuration
        .DESCRIPTION
            Unbind a system command policy to a given system group of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to add the binding to. Minimum length = 1
        .PARAMETER PolicyName
            Name of the command policy that is binded to the group.
        .EXAMPLE
            Remove-NSSystemGroupSystemCmdPolicyBinding -NSSession $Session -GroupName group -PolicyName commandpolicy
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName,
            [Parameter(Mandatory=$true)] [string]$PolicyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $args = @{policyname=$PolicyName}

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType systemgroup_systemcmdpolicy_binding -ResourceName $GroupName -Arguments $args

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Get-NSSystemGroupSystemCmdPolicyBinding {
        <#
        .SYNOPSIS
            Get the bound command policy(s) to a given system group of the NetScaler Configuration
        .DESCRIPTION
            Get the bound command policy(s) to a given system group of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to add the binding to. Minimum length = 1
        .EXAMPLE
            Remove-NSSystemGroupSystemCmdPolicyBinding -NSSession $Session -GroupName group -PolicyName commandpolicy
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemgroup_systemcmdpolicy_binding -ResourceName $GroupName

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['systemgroup_systemcmdpolicy_binding'])
        {
            return $response.systemgroup_systemcmdpolicy_binding
        }
        else
        {
            return $null
        }
    }

    #endregion
    #region DONE System - Authentication

    # Add-NSAuthLDAPAction is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
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
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType authenticationldapaction -Payload $payload  

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }

    function Update-NSAuthLDAPAction {
        <#
        .SYNOPSIS
            Update a new NetScaler LDAP action
        .DESCRIPTION
            Update a new NetScaler LDAP action
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
            Update-NSAuthLDAPAction -NSSession $Session -LDAPActionName "10.108.151.1_LDAP" -LDAPServerIP 10.8.115.245 -LDAPBaseDN "dc=xd,dc=local" -LDAPBindDN "administrator@xd.local" -LDAPBindDNPassword "passw0rd"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$LDAPActionName,
            [Parameter(Mandatory=$false)] [string]$LDAPServerIP,
            [Parameter(Mandatory=$false)] [string]$LDAPBaseDN,
            [Parameter(Mandatory=$false)] [string]$LDAPBindDN,
            [Parameter(Mandatory=$false)] [string]$LDAPBindDNPassword,
            [Parameter(Mandatory=$false)] [string]$LDAPLoginName="sAMAccountName"
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload =  @{name=$LDAPActionName}
        
        if (-not [string]::IsNullOrEmpty($LDAPServerIP)) 
        {
           $payload.Add("serverip",$LDAPServerIP)
        }
        if (-not [string]::IsNullOrEmpty($LDAPBaseDN)) 
        {
           $payload.Add("ldapbase",$LDAPBaseDN)
        }
        if (-not [string]::IsNullOrEmpty($LDAPBindDN)) 
        {
           $payload.Add("ldapbinddn",$LDAPBindDN)
        }
        if (-not [string]::IsNullOrEmpty($LDAPBindDN)) 
        {
           $payload.Add("ldapbinddnpassword",$LDAPBindDNPassword)
        }
        if (-not [string]::IsNullOrEmpty($LDAPLoginName)) 
        {
           $payload.Add("ldaploginname",$LDAPLoginName)
        }
      
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType authenticationldapaction -ResourceName $LDAPActionName -Payload $payload -Verbose:$VerbosePreference  

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Remove-NSAuthLDAPAction {
        <#
        .SYNOPSIS
            Remove a NetScaler LDAP action
        .DESCRIPTION
            Remove a NetScaler LDAP action
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER LDAPActionName
            Name of the LDAP action
        .EXAMPLE
            Remove-NSAuthLDAPAction -NSSession $Session -LDAPActionName "10.108.151.1_LDAP"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$LDAPActionName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType authenticationldapaction -ResourceName $LDAPActionName 

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Get-NSAuthLDAPAction {
        <#
        .SYNOPSIS
            Retrieve a NetScaler LDAP action
        .DESCRIPTION
            Retrieve a NetScaler LDAP action
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Get-NSAuthLDAPAction -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$LDAPActionName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        If ([string]::IsNullOrEmpty($LDAPActionName))
        {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType authenticationldapaction 
        }
        Else
        {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType authenticationldapaction -ResourceName $LDAPActionName 
        }


        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['authenticationldapaction'])
        {
            return $response.authenticationldapaction
        }
        else
        {
            return $null
        }
    }

    # Add-NSAuthLDAPPolicy is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    function Add-NSAuthLDAPPolicy {
        <#
        .SYNOPSIS
            Add a new NetScaler LDAP policy
        .DESCRIPTION
            Add a new NetScaler LDAP policy
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Action
            Name of the LDAP action to perform if the policy matches.
        .PARAMETER Name
            Name of the LDAP policy
        .PARAMETER RuleExpression
            Name of the NetScaler named rule, or a default syntax expression, that the policy uses to determine whether to attempt to authenticate the user with the LDAP server.
        .EXAMPLE
            Add-NSAuthLDAPPolicy -NSSession $Session -LDAPActionName "10.8.115.245_LDAP" -LDAPPolicyName "10.8.115.245_LDAP_pol" -LDAPRuleExpression NS_TRUE
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$Action,
            [Parameter(Mandatory=$true)] [string]$Name,
            [Parameter(Mandatory=$false)] [string]$RuleExpression="ns_true"
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload = @{reqaction=$Action;name=$Name;rule=$RuleExpression}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType authenticationldappolicy -Payload $payload  

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }

    function Update-NSAuthLDAPPolicy {
        <#
        .SYNOPSIS
            Update a NetScaler LDAP policy
        .DESCRIPTION
            Update a NetScaler LDAP policy
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the LDAP policy
        .PARAMETER RuleExpression
            Name of the NetScaler named rule, or a default syntax expression, that the policy uses to determine whether to attempt to authenticate the user with the LDAP server.
        .PARAMETER Action
            Name of the LDAP action to perform if the policy matches.
        .EXAMPLE
            Update-NSAuthLDAPPolicy -NSSession $Session -LDAPPolicyName "10.8.115.245_LDAP_pol" -LDAPRuleExpression NS_TRUE -LDAPActionName "10.8.115.245_LDAP" 
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$RuleExpression="ns_true",
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Action
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload = @{name=$Name;rule=$RuleExpression;reqaction=$Action}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType authenticationldappolicy -Payload $payload -Verbose:$VerbosePreference  

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Remove-NSAuthLDAPPolicy {
        <#
        .SYNOPSIS
            Remove a NetScaler LDAP policy
        .DESCRIPTION
            Remove a NetScaler LDAP policy
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the LDAP policy to remove.
        .EXAMPLE
            Remove-NSAuthLDAPPolicy -NSSession $Session -LDAPPolicyName "10.8.115.245_pol"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType authenticationldappolicy -ResourceName $Name -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Get-NSAuthLDAPPolicy {
        <#
        .SYNOPSIS
            Retrieve all NetScaler LDAP policies
        .DESCRIPTION
            Retrieve all NetScaler LDAP policies
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the LDAP policy
        .EXAMPLE
            Get-NSAuthLDAPPolicy -NSSession $Session
        .EXAMPLE
            Get-NSAuthLDAPPolicy -NSSession $Session -LDAPPolicyName $PolicyName
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$Name
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"
        If ([string]::IsNullOrEmpty($Name))
        {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType authenticationldappolicy
        }
        Else
        {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType authenticationldappolicy -ResourceName $Name
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['authenticationldappolicy'])
        {
            return $response.authenticationldappolicy
        }
        else
        {
            return $null
        }
    }

    function Show-NSAuthLDAPPolicyAuthVserverBindings {
        <#
        .SYNOPSIS
            Retrieve vServer bindings for given LDAPPolicy
        .DESCRIPTION
            Retrieve vServer bindings for given LDAPPolicy
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER PolicyName
            Name of the LDAP policy
        .EXAMPLE
            Get-NSAuthLDAPPolicyAuthVserverBinding -NSSession $Session -LDAPPolicyName $PolicyName
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$PolicyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType authenticationldappolicy_authenticationvserver_binding -ResourceName $PolicyName -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['authenticationldappolicy_authenticationvserver_binding'])
        {
            return $response.authenticationldappolicy_authenticationvserver_binding
        }
        else
        {
            return $null
        }
    }
    function Show-NSAuthLDAPPolicyBindings {
        <#
        .SYNOPSIS
            Retrieve resources that can be bound to the given LDAPPolicy
        .DESCRIPTION
            Retrieve resources that can be bound to the given LDAPPolicy
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER PolicyName
            Name of the LDAP policy
        .EXAMPLE
            Get-NSAuthLDAPPolicyBinding -NSSession $Session -LDAPPolicyName $PolicyName
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$PolicyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType authenticationldappolicy_binding -ResourceName $PolicyName -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['authenticationldappolicy_binding'])
        {
            return $response.authenticationldappolicy_binding
        }
        else
        {
            return $null
        }
    }
    #endregion

    #region System - Network
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    # Add-NSIPResource is part of the Citrix NITRO Module
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
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsip -Payload $payload 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }

    function Update-NSIPResource {
        <#
        .SYNOPSIS
            Update NetScaler IP resource(s)
        .DESCRIPTION
            Update NetScaler IP resource(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER IPAddress
            IPv4 address to create on the NetScaler appliance. Cannot be changed after the IP address is created
        .PARAMETER SubnetMask
            Subnet mask associated with the IP address
        .PARAMETER VServer
            Specify to use enable the vserver attribute for this IP entity
        .PARAMETER MgmtAccess
            Specify to allow access to management applications on this IP address
        .EXAMPLE
            Update Subnet IP
            Update-NSIPResource -NSSession $Session -IPAddress "10.108.151.2" -SubnetMask "255.255.248.0"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true,ValueFromPipeline=$true)] [string]$IPAddress,
            [Parameter(Mandatory=$false)] [string]$SubnetMask,
            [Parameter(Mandatory=$false)] [switch]$VServer,
            [Parameter(Mandatory=$false)] [switch]$MgmtAccess
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"

            $vserverState = if ($VServer) { "ENABLED" } else { "DISABLED" }
            $mgmtAccessState = if ($MgmtAccess) { "ENABLED" } else { "DISABLED" }
            
            If (!([string]::IsNullOrEmpty($SubnetMask)))
            {        
                Write-Verbose "Validating Subnet Mask"
                $SubnetMaskObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($SubnetMask,[ref]$SubnetMaskObj) -or $SubnetMaskObj.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
                    throw "'$SubnetMask' is an invalid IPv4 subnet mask"
                }
            }
        }
        Process {
            Write-Verbose "Validating IP Address"
            $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
            if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj) -or $IPAddressObj.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
                throw "'$IPAddress' is an invalid IPv4 address"
            }
        
            $payload = @{ipaddress=$IPAddress;netmask=$SubnetMask;vserver=$vserverState;mgmtaccess=$mgmtAccessState}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType nsip -Payload $payload -Verbose:$VerbosePreference 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Remove-NSIPResource {
        <#
        .SYNOPSIS
            Delete NetScaler IP resource(s)
        .DESCRIPTION
            Delete NetScaler IP resource(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER IPAddress
            IPv4 address that will be removed from the NetScaler appliance.
        .EXAMPLE
            Delete Subnet IP
            Remove-NSIPResource -NSSession $Session -IPAddress "10.108.151.2"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true,ValueFromPipeline=$true)] [string]$IPAddress
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"

        }
        Process {
            Write-Verbose "Validating IP Address"
            $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
            if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj) -or $IPAddressObj.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
                throw "'$IPAddress' is an invalid IPv4 address"
            }
        
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType nsip -ResourceName $IPAddress -Action delete
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Get-NSIPResource {
        <#
        .SYNOPSIS
            Retrieve NetScaler IP resource(s)
        .DESCRIPTION
            Retrieve NetScaler IP resource(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER IPAddress
            IPv4 address that will be retrieved from the NetScaler appliance.
        .EXAMPLE
            Get-NSIPResource -NSSession $Session -IPAddress "10.108.151.2"
        .EXAMPLE
            Get-NSIPResource -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false,ValueFromPipeline=$true)] [string]$IPAddress
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"

        }
        Process {
            If ($IPAddress) {
                Write-Verbose "Validating IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj) -or $IPAddressObj.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
                    throw "'$IPAddress' is an invalid IPv4 address"
                }
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsip -ResourceName $IPAddress -Action get
            }
            Else
            {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsip -Action get
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['nsip'])
            {
                return $response.nsip
            }
            else
            {
                return $null
            }
        }
    }

    #endregion

#endregion

#region AppExpert
    #region DONE AppExpert - Rewrite
    function Add-NSRewriteAction {
        <#
        .SYNOPSIS
            Add a Rewrite Action to the NetScalerConfiguration
        .DESCRIPTION
            Add a Rewrite Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined rewrite action.
        .PARAMETER ActionType
            Type of user-defined rewrite action. 
            Possible values = noop, delete, insert_http_header, delete_http_header, corrupt_http_header, 
            insert_before, insert_after, replace, replace_http_res, delete_all, replace_all, 
            insert_before_all, insert_after_all, clientless_vpn_encode, clientless_vpn_encode_all, 
            clientless_vpn_decode, clientless_vpn_decode_all, insert_sip_header, delete_sip_header, 
            corrupt_sip_header, replace_sip_res, replace_diameter_header_field, replace_dns_header_field, 
            replace_dns_answer_section
        .PARAMETER TargetExpression
            Default syntax expression that specifies which part of the request or response to rewrite. Minimum length = 1
        .PARAMETER Expression
            Default syntax expression that specifies the content to insert into the request or response at the specified location, or that replaces the specified string.
        .EXAMPLE
            Add-NSRewriteAction -NSSession $Session -ActionName $ActionName -ActionType replace -TargetExpression "HTTP.REQ.URL" -Expression "\"/Citrix/XenApp\""
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$ActionName,
            [Parameter(Mandatory=$true)][ValidateScript({
                if ($NSRewriteActionTypes -contains $_) 
                {
                    $true
                } 
                else 
                {
                    throw "Valid values are: $($NSRewriteActionTypes -join ', ')"
                }
            })] [string]$ActionType,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$TargetExpression,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Expression,
            [Parameter(Mandatory=$false)][ValidateScript({$ActionType -eq "insert_http_header"})] [string]$HeaderName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $payload = @{name=$ActionName;type=$ActionType;target=$TargetExpression;stringbuilderexpr=$Expression}

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType rewriteaction -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Import-NSRewriteActionTypes {
        #Count is 23 action types
        return @(
            'noop', 'delete',
            'insert_http_header','delete_http_header','corrupt_http_header',
            'insert_before','insert_after','replace','replace_http_res','delete_all',
            'insert_before_all','insert_after_all','clientless_vpn_encode','clientless_vpn_encode_all',
            'clientless_vpn_decode','clientless_vpn_decode_all',
            'insert_sip_header','delete_sip_header','corrupt_sip_header',
            'replace_res_res','replace_diameter_header_field','replace_dns_header_field','replace_dns_answer_section'
        )
    }
    Set-Variable -Name NSRewriteActionTypes -Value $(Import-NSRewriteActionTypes) -Option Constant
    function Update-NSRewriteAction {
        <#
        .SYNOPSIS
            Update a Rewrite Action to the NetScalerConfiguration
        .DESCRIPTION
            Update a Rewrite Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined rewrite action.
        .PARAMETER TargetExpression
            Default syntax expression that specifies which part of the request or response to rewrite. Minimum length = 1
        .PARAMETER Expression
            Default syntax expression that specifies the content to insert into the request or response at the specified location, or that replaces the specified string.
        .EXAMPLE
            Update-NSRewriteAction -NSSession $Session -ActionName $ActionName -ActionType replace -TargetExpression "HTTP.REQ.URL" -Expression "\"/Citrix/XenApp\""
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$ActionName,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$TargetExpression,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Expression,
            [Parameter(Mandatory=$false)] [string]$HeaderName,
            [Parameter(Mandatory=$false)] [string]$Comment
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $payload = @{name=$ActionName;target=$TargetExpression;stringbuilderexpr=$Expression}
            If (!([string]::IsNullOrEmpty($Comment)))
            {
                $payload.Add("comment",$Comment)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType rewriteaction -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Remove-NSRewriteAction {
        <#
        .SYNOPSIS
            Remove a Rewrite Action to the NetScalerConfiguration
        .DESCRIPTION
            Remove a Rewrite Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined rewrite action.
        .EXAMPLE
            Remove-NSRewriteAction -NSSession $Session -ActionName $ActionName
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$ActionName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType rewriteaction -ResourceName $ActionName
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Get-NSRewriteAction {
        <#
        .SYNOPSIS
            Retrieve a Rewrite Action to the NetScalerConfiguration
        .DESCRIPTION
            Retrieve a Rewrite Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined rewrite action.
        .EXAMPLE
            Get-NSRewriteAction -NSSession $Session -ActionName $ActionName
        .EXAMPLE
            Get-NSRewriteAction -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]  [string]$ActionName,
            [Parameter(Mandatory=$false)] [switch]$ShowBuiltIn
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($ActionName) {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType rewriteaction -ResourceName $ActionName
            }
            Else
            {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType rewriteaction
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['rewriteaction'])
            {
                If ($ShowBuiltIn)
                {
                    return $response.rewriteaction
                }
                Else
                {
                    return $response.rewriteaction | Where-Object {$_.isdefault -eq $false}
                }
            }
            else
            {
                return $null
            }
        }
    }

    function Add-NSRewritePolicy {
        <#
        .SYNOPSIS
            Add a Rewrite Policy to the NetScalerConfiguration
        .DESCRIPTION
            Add a Rewrite Policy to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER PolicyName
            Name for the rewrite policy.
        .PARAMETER PolicyAction
            Name of the rewrite action to perform if the request or response matches this rewrite policy.
        .PARAMETER PolicyRule
            Expression against which traffic is evaluated.
        .PARAMETER Expression
            Default syntax expression that specifies the content to insert into the request or response at the specified location, or that replaces the specified string.
        .EXAMPLE
            Update-NSRewritePolicy -NSSession $Session -PolicyName $PolicyName -PolicyAction $PolicyAction -PolicyRule "HTTP.REQ.URL.EQ(""/"")" -Comment "newly added"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$PolicyName,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$PolicyAction,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$PolicyRule,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Comment
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $payload = @{name=$PolicyName;action=$PolicyAction;rule=$PolicyRule}
            If (!([string]::IsNullOrEmpty($Comment)))
            {
                $payload.Add("comment",$Comment)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType rewritepolicy -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Update-NSRewritePolicy {
        <#
        .SYNOPSIS
            Update a Rewrite Policy to the NetScalerConfiguration
        .DESCRIPTION
            Update a Rewrite Policy to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER PolicyName
            Name for the rewrite policy.
        .PARAMETER PolicyAction
            Name of the rewrite action to perform if the request or response matches this rewrite policy.
        .PARAMETER PolicyRule
            Expression against which traffic is evaluated.
        .PARAMETER Expression
            Default syntax expression that specifies the content to insert into the request or response at the specified location, or that replaces the specified string.
        .EXAMPLE
            Update-NSRewritePolicy -NSSession $Session -PolicyName $PolicyName -PolicyAction $PolicyAction -PolicyRule "HTTP.REQ.URL.EQ(""/"")" -Comment "updated"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$PolicyName,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$PolicyAction,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$PolicyRule,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Comment
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $payload = @{name=$PolicyName}
            
            If (!([string]::IsNullOrEmpty($PolicyAction)))
            {
                $payload.Add("action",$PolicyAction)
            }
            If (!([string]::IsNullOrEmpty($PolicyRule)))
            {
                $payload.Add("rule",$PolicyRule)
            }
            If (!([string]::IsNullOrEmpty($Comment)))
            {
                $payload.Add("comment",$Comment)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType rewritepolicy -Payload $payload -Verbose:$VerbosePreference 
        }
    }
    function Remove-NSRewritePolicy {
        <#
        .SYNOPSIS
            Remove a Rewrite Policy to the NetScalerConfiguration
        .DESCRIPTION
            remove a Rewrite Policy to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER PolicyName
            Name for the rewrite policy.
        .EXAMPLE
            Remove-NSRewritePolicy -NSSession $Session -PolicyName $PolicyName
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$PolicyName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType rewritepolicy -ResourceName $PolicyName
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Get-NSRewritePolicy {
        <#
        .SYNOPSIS
            Retrieve a Rewrite Policy to the NetScalerConfiguration
        .DESCRIPTION
            Retrieve a Rewrite Policy to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER PolicyName
            Name for the rewrite policy.
        .PARAMETER ShowBuiltIn
            Include default rewritepolicies in results.
        .EXAMPLE
            Get-NSRewritePolicy -NSSession $Session -PolicyName $PolicyName
        .EXAMPLE
            Get-NSRewritePolicy -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]  [string]$PolicyName,
            [Parameter(Mandatory=$false)] [switch]$ShowBuiltIn
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($PolicyName) {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType rewritepolicy -ResourceName $PolicyName
            }
            Else
            {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType rewritepolicy
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['rewritepolicy'])
            {
                If ($ShowBuiltIn)
                {
                    return $response.rewritepolicy
                }
                Else
                {
                    return $response.rewritepolicy | Where-Object {$_.isdefault -eq $false}
                }
            }
            else
            {
                return $null
            }
        }
    }
    #endregion

    #region DONE AppExpert - Responder
    function Add-NSResponderAction {
        <#
        .SYNOPSIS
            Add a Responder Action to the NetScalerConfiguration
        .DESCRIPTION
            Add a Responder Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined responder action.
        .PARAMETER ActionType
            Type of user-defined responder action. 
            Possible values = noop, respondwith, redirect, respondwithhtmlpage, sqlresponse_ok, sqlresponse_error
        .PARAMETER TargetExpression
            Expression specifying what to respond with. Typically a URL for redirect policies or a default-syntax expression.
        .PARAMETER HTLMPage
            For respondwithhtmlpage policies, name of the HTML page object to use as the response. You must first import the page object. Minimum length = 1
        .PARAMETER BypassSafetyCheck
            Bypass the safety check, allowing potentially unsafe expressions. Default value: NO. Possible values = YES, NO
        .PARAMETER ResponseStatusCode
            HTTP response status code, for example 200, 302, 404, etc. The default value for the redirect action type is 302 and for respondwithhtmlpage is 200. Minimum value = 100. Maximum value = 599
        .PARAMETER ReasonPhrase
            Expression specifying the reason phrase of the HTTP response. The reason phrase may be a string literal with quotes or a PI expression. For example: "Invalid URL: " + HTTP.REQ.URL.
        .EXAMPLE
            Add-NSRewriteAction -NSSession $Session -ActionName $ActionName -ActionType replace -TargetExpression "HTTP.REQ.URL" -Expression "\"/Citrix/XenApp\""
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$ActionName,
            [Parameter(Mandatory=$true)][ValidateScript({
                if ($NSResponderActionTypes -contains $_) 
                {
                    $true
                } 
                else 
                {
                    throw "Valid values are: $($NSResponderActionTypes -join ', ')"
                }
            })] [string]$ActionType,
            [Parameter(Mandatory=$false)][string]$TargetExpression,
            [Parameter(Mandatory=$false)][ValidateScript({$ActionType -eq "respondwithhtmlpage"})] [string]$HTMLPage,
            [Parameter(Mandatory=$false)][ValidateSet("YES","NO")] [string]$BypassSafetyCheck="NO",
            [Parameter(Mandatory=$false)] [string]$Comment,
            [Parameter(Mandatory=$false)][ValidateRange(100,599)] [int]$ResponseStatusCode,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$ReasonPhrase
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $payload = @{name=$ActionName;type=$ActionType;bypasssafetycheck=$BypassSafetyCheck}

            if (-not [string]::IsNullOrEmpty($TargetExpression)) 
            {
               $payload.Add("target",$TargetExpression)
            }
            if (-not [string]::IsNullOrEmpty($HTMLPage)) 
            {
               $payload.Add("htmlpage",$HTMLPage)
            }
            if ($ResponseStatusCode) {
                $payload.Add("responsestatuscode",$ResponseStatusCode)
            }
            if (-not [string]::IsNullOrEmpty($Comment)) 
            {
               $payload.Add("comment",$Comment)
            }
            if (-not [string]::IsNullOrEmpty($ReasonPhrase)) 
            {
               $payload.Add("reasonphrase",$ReasonPhrase)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType responderaction -Payload $payload -Verbose:$VerbosePreference 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Import-NSResponderActionTypes {
        #Count is 6 action types
        return @('noob', 'respondwith', 'redirect', 'respondwithhtmlpage', 'sqlresponse_ok','sqlresponse_error')
    }
    Set-Variable -Name NSResponderActionTypes -Value $(Import-NSResponderActionTypes) -Option Constant
    function Update-NSResponderAction {
        <#
        .SYNOPSIS
            Add a Responder Action to the NetScalerConfiguration
        .DESCRIPTION
            Add a Responder Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined responder action.
        .PARAMETER ActionType
            Type of user-defined responder action. 
            Possible values = noop, respondwith, redirect, respondwithhtmlpage, sqlresponse_ok, sqlresponse_error
        .PARAMETER TargetExpression
            Expression specifying what to respond with. Typically a URL for redirect policies or a default-syntax expression.
        .PARAMETER HTLMPage
            For respondwithhtmlpage policies, name of the HTML page object to use as the response. You must first import the page object. Minimum length = 1
        .PARAMETER BypassSafetyCheck
            Bypass the safety check, allowing potentially unsafe expressions. Default value: NO. Possible values = YES, NO
        .PARAMETER ResponseStatusCode
            HTTP response status code, for example 200, 302, 404, etc. The default value for the redirect action type is 302 and for respondwithhtmlpage is 200. Minimum value = 100. Maximum value = 599
        .PARAMETER ReasonPhrase
            Expression specifying the reason phrase of the HTTP response. The reason phrase may be a string literal with quotes or a PI expression. For example: "Invalid URL: " + HTTP.REQ.URL.
        .EXAMPLE
            Add-NSRewriteAction -NSSession $Session -ActionName $ActionName -ActionType replace -TargetExpression "HTTP.REQ.URL" -Expression "\"/Citrix/XenApp\""
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$ActionName,
            [Parameter(Mandatory=$false)][string]$TargetExpression,
            [Parameter(Mandatory=$false)][ValidateScript({$ActionType -eq "respondwithhtmlpage"})] [string]$HTMLPage,
            [Parameter(Mandatory=$false)][ValidateSet("YES","NO")] [string]$BypassSafetyCheck,
            [Parameter(Mandatory=$false)] [string]$Comment,
            [Parameter(Mandatory=$false)][ValidateRange(100,599)] [int]$ResponseStatusCode,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$ReasonPhrase
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $payload = @{name=$ActionName}

            if (-not [string]::IsNullOrEmpty($TargetExpression)) 
            {
               $payload.Add("target",$TargetExpression)
            }
            if (-not [string]::IsNullOrEmpty($BypassSafetyCheck)) 
            {
               $payload.Add("bypasssafetycheck",$BypassSafetyCheck)
            }
            if (-not [string]::IsNullOrEmpty($HTMLPage)) 
            {
               $payload.Add("htmlpage",$HTMLPage)
            }
            if ($ResponseStatusCode) {
                $payload.Add("responsestatuscode",$ResponseStatusCode)
            }
            if (-not [string]::IsNullOrEmpty($Comment)) 
            {
               $payload.Add("comment",$Comment)
            }
            if (-not [string]::IsNullOrEmpty($ReasonPhrase)) 
            {
               $payload.Add("reasonphrase",$ReasonPhrase)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType responderaction -Payload $payload -Verbose:$VerbosePreference 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Remove-NSResponderAction {
        <#
        .SYNOPSIS
            Remove a Rewrite Action to the NetScalerConfiguration
        .DESCRIPTION
            Remove a Rewrite Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined rewrite action.
        .EXAMPLE
            Remove-NSRewriteAction -NSSession $Session -ActionName $ActionName
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$ActionName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType responderaction -ResourceName $ActionName
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Get-NSResponderAction {
        <#
        .SYNOPSIS
            Retrieve a Responder Action to the NetScalerConfiguration
        .DESCRIPTION
            Retrieve a Responder Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined rewrite action.
        .EXAMPLE
            Get-NSResponderAction -NSSession $Session -ActionName $ActionName
        .EXAMPLE
            Get-NSResponderAction -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]  [string]$ActionName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($ActionName) {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType responderaction -ResourceName $ActionName
            }
            Else
            {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType responderaction
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['responderaction'])
            {
                return $response.responderaction
            }
            else
            {
                return $null
            }
        }
    }

    function Add-NSResponderPolicy {
        <#
        .SYNOPSIS
            Add a Rewrite Policy to the NetScalerConfiguration
        .DESCRIPTION
            Add a Rewrite Policy to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name for the responder policy.
        .PARAMETER Rule
            Default syntax expression that the policy uses to determine whether to respond to the specified request.
        .PARAMETER Action
            Name of the responder action to perform if the request matches this responder policy.
        .PARAMETER UndefAction
            Action to perform if the result of policy evaluation is undefined (UNDEF). 
        .PARAMETER Comment
            Any type of information about this responder policy.
        .PARAMETER LogAction
            Name of the messagelog action to use for requests that match this policy.
        .PARAMETER AppflowAction
            AppFlow action to invoke for requests that match this policy.
        .EXAMPLE
            Update-NSRewritePolicy -NSSession $Session -PolicyName $PolicyName -PolicyAction $PolicyAction -PolicyRule "HTTP.REQ.URL.EQ(""/"")" -Comment "newly added"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$Name,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$Rule,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Action,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$UndefAction,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Comment,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$LogAction,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$AppflowAction
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $payload = @{name=$Name;rule=$Rule;action=$Action}
            If (!([string]::IsNullOrEmpty($UndefAction)))
            {
                $payload.Add("undefaction",$UndefAction)
            }
            If (!([string]::IsNullOrEmpty($Comment)))
            {
                $payload.Add("comment",$Comment)
            }
            If (!([string]::IsNullOrEmpty($LogAction)))
            {
                $payload.Add("logaction",$LogAction)
            }
            If (!([string]::IsNullOrEmpty($AppflowAction)))
            {
                $payload.Add("appflowaction",$AppflowAction)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType responderpolicy -Payload $payload -Verbose:$VerbosePreference 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Update-NSResponderPolicy {
        <#
        .SYNOPSIS
            Add a Rewrite Policy to the NetScalerConfiguration
        .DESCRIPTION
            Add a Rewrite Policy to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name for the responder policy.
        .PARAMETER Rule
            Default syntax expression that the policy uses to determine whether to respond to the specified request.
        .PARAMETER Action
            Name of the responder action to perform if the request matches this responder policy.
        .PARAMETER UndefAction
            Action to perform if the result of policy evaluation is undefined (UNDEF). 
        .PARAMETER Comment
            Any type of information about this responder policy.
        .PARAMETER LogAction
            Name of the messagelog action to use for requests that match this policy.
        .PARAMETER AppflowAction
            AppFlow action to invoke for requests that match this policy.
        .EXAMPLE
            Update-NSRewritePolicy -NSSession $Session -PolicyName $PolicyName -PolicyAction $PolicyAction -PolicyRule "HTTP.REQ.URL.EQ(""/"")" -Comment "newly added"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$Name,
            [Parameter(Mandatory=$false)] [string]$Rule,
            [Parameter(Mandatory=$false)] [string]$Action,
            [Parameter(Mandatory=$false)] [string]$UndefAction,
            [Parameter(Mandatory=$false)] [string]$Comment,
            [Parameter(Mandatory=$false)] [string]$LogAction,
            [Parameter(Mandatory=$false)] [string]$AppflowAction
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $payload = @{name=$Name}
            If (!([string]::IsNullOrEmpty($Rule)))
            {
                $payload.Add("rule",$Rule)
            }
            If (!([string]::IsNullOrEmpty($Action)))
            {
                $payload.Add("action",$Action)
            }
            If (!([string]::IsNullOrEmpty($UndefAction)))
            {
                $payload.Add("undefaction",$UndefAction)
            }
            If (!([string]::IsNullOrEmpty($Comment)))
            {
                $payload.Add("comment",$Comment)
            }
            If (!([string]::IsNullOrEmpty($LogAction)))
            {
                $payload.Add("logaction",$LogAction)
            }
            If (!([string]::IsNullOrEmpty($AppflowAction)))
            {
                $payload.Add("appflowaction",$AppflowAction)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType responderpolicy -Payload $payload -Verbose:$VerbosePreference 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Remove-NSResponderPolicy {
        <#
        .SYNOPSIS
            Remove a Rewrite Action to the NetScalerConfiguration
        .DESCRIPTION
            Remove a Rewrite Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined rewrite action.
        .EXAMPLE
            Remove-NSRewriteAction -NSSession $Session -ActionName $ActionName
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$Name
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType responderpolicy -ResourceName $Name
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Get-NSResponderPolicy {
        <#
        .SYNOPSIS
            Retrieve a Responder Action to the NetScalerConfiguration
        .DESCRIPTION
            Retrieve a Responder Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined rewrite action.
        .EXAMPLE
            Get-NSResponderAction -NSSession $Session -ActionName $ActionName
        .EXAMPLE
            Get-NSResponderAction -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]  [string]$Name,
            [Parameter(Mandatory=$false)] [switch]$ShowBuiltIn
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($Name) {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType responderpolicy -ResourceName $Name -Verbose
            }
            Else
            {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType responderpolicy
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['responderpolicy'])
            {
                If ($ShowBuiltIn)
                {
                    return $response.responderpolicy
                }
                Else
                {
                    # The builtin property is not set for user created policies. Only select objects that do not have the builtin property.
                    return $response.responderpolicy | Where-Object {!($_.PSObject.Properties['builtin'])} -ErrorAction SilentlyContinue
                }
            }
            else
            {
                return $null
            }
        }
    }
    #endregion

#endregion

# NOTE: Onwards to Traffic Management functions !!!

#region Traffic Management
    #region Traffic Management - Load Balancing
        #region Load Balancing - Servers
        # Add-NSServer is part of the Citrix NITRO Module
        # Copied from Citrix's Module to ensure correct scoping of variables and functions
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
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType server -Payload $payload  
   
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }

        function Update-NSServer {
            <#
            .SYNOPSIS
                Update a server resource
            .DESCRIPTION
                Update a server resource
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the server
            .PARAMETER IPAddress
                IPv4 or IPv6 address of the server. If you create an IP address based server, you can specify the name of the server, instead of its IP address, when creating a service. 
                Note: If you do not create a server entry, the server IP address that you enter when you create a service becomes the name of the server.
            .PARAMETER DomainResolveRetry
                Time, in seconds, for which the NetScaler appliance must wait, after DNS resolution fails, before sending the next DNS query to resolve the domain name. Default value: 5. Minimum value = 5. Maximum value = 20939
            .PARAMETER TranslationIP
                IP address used to transform the server's DNS-resolved IP address.
            .PARAMETER TranslationMask
                The netmask of the translation ip.
            .PARAMETER DomainResolveNow
                Immediately send a DNS query to resolve the server's domain name.
            .PARAMETER Comment
                Any information about the server.
            .EXAMPLE
                Add-NSServer -NSSession $Session -ServerName "myServer" -ServerIPAddress "10.108.151.3"
            .NOTES
                Copyright (c) Citrix Systems, Inc. All rights reserved.
            #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$Name,
                [Parameter(Mandatory=$false)] [string]$IPAddress,
                [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Comment
        #        [Parameter(Mandatory=$false)] [string]$TranslationIP,
        #        [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$TranslationMask,
        #        [Parameter(Mandatory=$false)][ValidateRange(5,20939)] [int]$DomainResolveRetry,
        #        [Parameter(Mandatory=$false)] [switch]$DomainResolveNow
            )

        # NOTE: To Be Resolved ??
            # Invoke-RestMethod : { "errorcode": 1092, "message": "Arguments cannot both be specified [domainResolveRetry, IPAddress]", "severity": "ERROR" }
            # Invoke-RestMethod : { "errorcode": 2193, "message": "Resolve retry can be set only on domain based servers", "severity": "ERROR" }
            # Invoke-RestMethod : { "errorcode": 1097, "message": "Invalid argument value [domainresolvenow]", "severity": "ERROR"}
            # Invoke-RestMethod : { "errorcode": 1, "message": "[The translationIP\/Mask can be set only for domain based servers.]", "severity": "ERROR" }

        # When a Server is added you can select IP Address (only enter an IP address, traffic domain and comment)
        # Or Domain Name (enter FQDN, Traffic Domain, Translation IP Address, Translation Mask, Resolve Retry, IPv6 Domain, Enable after Creating and Comments)

            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        #    $DomainResolveNowState = if ($DomainResolveNow) { "True" } else { "False" }

        #    $payload = @{name=$Name;domainresolvenow=$DomainResolveNowState}
            $payload = @{name=$Name}

            If (!([string]::IsNullOrEmpty($IPAddress)))
            {
                Write-Verbose "Validating IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj)) {
                    throw "'$IPAddress' is an invalid IP address"
                }
                $payload.Add("ipaddress",$IPAddress)
            }
        <#    If ($DomainResolveRetry)
            {
                $payload.Add("domainresolveretry",$DomainResolveRetry)
            }
            If (!([string]::IsNullOrEmpty($TranslationIP)))
            {
                Write-Verbose "Validating Translation IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($TranslationIP,[ref]$IPAddressObj)) {
                    throw "'$TranslationIP' is an invalid IP address"
                }
                $payload.Add("translationip",$TranslationIP)
            }
            If (!([string]::IsNullOrEmpty($TranslationMask)))
            {
                $payload.Add("translationmask",$TranslationMask)
            }
        #>
            If (!([string]::IsNullOrEmpty($Comment)))
            {
                $payload.Add("comment",$Comment)
            }
    
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType server -Payload $payload -Verbose:$VerbosePreference  
   
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
        function Remove-NSServer{
            <#
            .SYNOPSIS
                Remove a NetScaler Server from the NetScalerConfiguration
            .DESCRIPTION
                Remove a NetScaler Server from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the Server.
            .EXAMPLE
                Remove-NSServer -NSSession $Session -Name $ServerName
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType server -ResourceName $Name -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
        function Get-NSServer {
            <#
            .SYNOPSIS
                Retrieve a Server from the NetScalerConfiguration
            .DESCRIPTION
                Retrieve a Server from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name for the server. Can be changed after the name is created. Minimum length = 1.
            .PARAMETER Name
                Name of the server. Can be changed after the name is created. Minimum length = 1.
            .EXAMPLE
                Get-NSServer -NSSession $Session -Name $ServerName
            .EXAMPLE
                Get-NSServer -NSSession $Session
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
            }
            Process {
                If ($Name) {
                    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType server -ResourceName $Name -Verbose
                }
                Else
                {
                    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType server
                }
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
                If ($response.PSObject.Properties['server'])
                {
                    return $response.server
                }
                else
                {
                    return $null
                }
            }

        }

        function Enable-NSServer {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
                $payload = @{name=$Name}
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType server -Payload $payload -Verbose:$VerbosePreference -Action enable
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
        function Disable-NSServer {
            <#
            .SYNOPSIS
                Disable the NetScaler Server
            .DESCRIPTION
                Disable the NetScaler Server
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the server. Can be changed after the name is created. Minimum length = 1.
            .PARAMETER Delay
                Time, in seconds, after which all the services configured on the server are disabled.
            .PARAMETER Graceful
                Shut down gracefully, without accepting any new connections, and disabling each service when all of its connections are closed. Default value: NO. Possible values = YES, NO
            .EXAMPLE
                Disable-NSServer -NSSession $Session -Name $ServerName
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
                [Parameter(Mandatory=$false)][int]$Delay,
                [Parameter(Mandatory=$false)] [switch]$Graceful
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
                <#
                disable

                URL:http://<NSIP>/nitro/v1/config/

                HTTP Method:POST

                Request Payload:JSON

                object={
                "params":{
                      "warning":<String_value>,
                      "onerror":<String_value>,
                      "action":"disable"
                },
                "sessionid":"##sessionid",
                "server":{
                      "name":<String_value>,
                }}

                Response Payload:JSON

                { "errorcode": 0, "message": "Done", "severity": <String_value> }            
                #>
                $GracefulState = if ($Graceful) { "YES" } else { "NO" }

                $payload = @{name=$Name;graceful=$GracefulState}
                If ($Delay)
                {
                    $payload.Add("delay", $Delay)
                }
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType server -Payload $payload -Verbose:$VerbosePreference -Action disable
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
        #endregion

        #region Load Balancing - Services
        # UPDATED Add-NSService is part of the Citrix NITRO Module
        # Copied from Citrix's Module to ensure correct scoping of variables and functions
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
            .PARAMETER Protocol
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
                )] [string]$Protocol,
                [Parameter(Mandatory=$true)] [ValidateRange(1,65535)] [int]$Port,
                [Parameter(Mandatory=$false)] [switch]$InsertClientIPHeader,
                [Parameter(Mandatory=$false)] [string]$ClientIPHeader
            )

            Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
            $cip = if ($InsertClientIPHeader) { "ENABLED" } else { "DISABLED" }
            $payload = @{name=$Name;servicetype=$Protocol;port=$Port;cip=$cip}
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

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType service -Payload $payload  -Verbose:$VerbosePreference
   
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }

        function Update-NSService{
            <#
            .SYNOPSIS
                Update a service resource
            .DESCRIPTION
                Update a service resource
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name for the service
            .PARAMETER ServerName
                Name of the server that hosts the service
            .PARAMETER ServerIPAddress
                IPv4 or IPv6 address of the server that hosts the service
                By providing this parameter, it attempts to create a server resource for you that's named the same as the IP address provided
            .PARAMETER Protocol
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
                [Parameter(Mandatory=$false,ParameterSetName='By Address')] [string]$ServerIPAddress,
                [Parameter(Mandatory=$false)] [switch]$InsertClientIPHeader,
                [Parameter(Mandatory=$false)] [string]$ClientIPHeader,
                [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Comment
            )

            Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
            $cip = if ($InsertClientIPHeader) { "ENABLED" } else { "DISABLED" }
            $payload = @{name=$Name;cip=$cip}
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
            If (!([string]::IsNullOrEmpty($Comment)))
            {
                $payload.Add("comment",$Comment)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType service -Payload $payload  -Verbose:$VerbosePreference
   
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
    
        }
        function Remove-NSService{
            <#
            .SYNOPSIS
                Remove a NetScaler Service from the NetScalerConfiguration
            .DESCRIPTION
                Remove a NetScaler Service from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the Service.
            .EXAMPLE
                Remove-NSServer -NSSession $Session -Name $ServerName
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType service -ResourceName $Name -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
    
        }
        function Get-NSService{
            <#
            .SYNOPSIS
                Retrieve a Service from the NetScalerConfiguration
            .DESCRIPTION
                Retrieve a Service from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name for the service. Can be changed after the name is created. Minimum length = 1.
            .EXAMPLE
                Get-NSService -NSSession $Session -Name $ServiceName
            .EXAMPLE
                Get-NSService -NSSession $Session
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
            }
            Process {
                If ($Name) {
                    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType service -ResourceName $Name -Verbose:$VerbosePreference
                }
                Else
                {
                    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType service -Verbose:$VerbosePreference
                }
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
                If ($response.PSObject.Properties['service'])
                {
                    return $response.service
                }
                else
                {
                    return $null
                }
            }

    
        }

        function Enable-NSService {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
                $payload = @{name=$Name}
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType service -Payload $payload -Verbose:$VerbosePreference -Action enable
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
    # SOLVED: Disable-NSService renders the NetScaler unresponsive (stupid me bound the service to localhost on HTTP 80 (same as REST Web services) DOH!)
        function Disable-NSService {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
                [Parameter(Mandatory=$false,ParameterSetName='Graceful')] [switch]$Graceful,
                [Parameter(Mandatory=$false,ParameterSetName='Graceful')][double]$Delay
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
                $GracefulState = if ($Graceful) { "YES" } else { "NO" }

                $payload = @{name=$Name;graceful=$GracefulState}
                if ($PSCmdlet.ParameterSetName -eq 'Graceful') {
                    Write-Verbose "Graceful shutdown requested for service"
                    If ($Delay)
                    {
                        $payload.Add("delay", $Delay)
                    }
                }
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType service -Payload $payload -Verbose:$VerbosePreference -Action disable
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }

        #endregion
        #region Load Balancing - ServiceGroups
        function Add-NSServiceGroup {
            <#
            .SYNOPSIS
                Add a new service group
            .DESCRIPTION
                Add a new service group
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name for the service
            .PARAMETER Protocol
                Protocol in which data is exchanged with the service
            .PARAMETER CacheType
                Cache type supported by the cache server. Possible values = TRANSPARENT, REVERSE, FORWARD
            .PARAMETER AutoscaleMode
                Auto scale option for a servicegroup. Default value: DISABLED. Possible values = DISABLED, DNS, POLICY
            .PARAMETER Cacheable
                Use the transparent cache redirection virtual server to forward the request to the cache server. Note: Do not set this parameter if you set the Cache Type. Default value: NO. Possible values = YES, NO
            .SWITCH Disabled
                DisablesInitial state of the service group. Default value: ENABLED. Possible values = ENABLED, DISABLED
            .PARAMETER HealthMonitoring
                Monitor the health of this service. Available settings function as follows: YES - Send probes to check the health of the service. NO - Do not send probes to check the health of the service. With the NO option, the appliance shows the service as UP at all times. Default value: YES. Possible values = YES, NO
            .PARAMETER ApplfowLogging
                Enable logging of AppFlow information for the specified service group. Default value: ENABLED. Possible values = ENABLED, DISABLED
            .EXAMPLE
                Add-NSServiceGroup -NSSession $Session -Name "svcgrp" -Protocol "HTTP" -CacheType SERVER -AutoscaleMode "DISABLED" 
            .NOTES
                Copyright (c) Citrix Systems, Inc. All rights reserved.
            #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)] [string]$Name,
                [Parameter(Mandatory=$true)] [ValidateSet(
                "HTTP","FTP","TCP","UDP","SSL","SSL_BRIDGE","SSL_TCP","DTLS","NNTP","RPCSVR","DNS","ADNS","SNMP","RTSP","DHCPRA",
                "ANY","SIP_UDP","DNS_TCP","ADNS_TCP","MYSQL","MSSQL","ORACLE","RADIUS","RDP","DIAMETER","SSL_DIAMETER","TFTP"
                )] [string]$Protocol,
                [Parameter(Mandatory=$true)] [ValidateSet("SERVER", "TRANSPARENT", "REVERSE", "FORWARD")] [string]$CacheType,
                [Parameter(Mandatory=$true)] [ValidateSet("DISABLED", "DNS", "POLICY")] [string]$AutoscaleMode,
                [Parameter(Mandatory=$false)] [ValidateScript({($CacheType -eq "SERVER")})][switch]$Cacheable,
                [Parameter(Mandatory=$false)] [ValidateSet("ENABLED", "DISABLED")] [string]$State="ENABLED",
                [Parameter(Mandatory=$false)] [switch]$HealthMonitoring,
                [Parameter(Mandatory=$false)] [switch]$AppflowLogging
            )

            Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
            $CacheableValue = if ($Cacheable) { "YES" } else { "NO" }
            $HealthMonValue = if ($HealthMonitoring) { "YES" } else { "NO" }
            $AppflowLogValue = if ($AppflowLogging) { "ENABLED" } else { "DISABLED" }

            $payload = @{servicegroupname=$Name;servicetype=$Protocol;state=$State;healthmonitor=$HealthMonValue;appflowlog=$AppflowLogValue}
            If ($CacheType -eq "SERVER")
            {
                $payload.Add("cacheable", $CacheableValue)
            }
            Else
            {
                $payload.Add("cachetype", $CacheType)
            }
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType servicegroup -Payload $payload  -Verbose:$VerbosePreference
   
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
        function Update-NSServiceGroup {
            <#
            .SYNOPSIS
                Update a service group
            .DESCRIPTION
                Update a service group
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name for the service
            .PARAMETER Protocol
                Protocol in which data is exchanged with the service
            .PARAMETER CacheType
                Cache type supported by the cache server. Possible values = TRANSPARENT, REVERSE, FORWARD
            .PARAMETER Cacheable
                Use the transparent cache redirection virtual server to forward the request to the cache server. Note: Do not set this parameter if you set the Cache Type. Default value: NO. Possible values = YES, NO
            .SWITCH Disabled
                DisablesInitial state of the service group. Default value: ENABLED. Possible values = ENABLED, DISABLED
            .PARAMETER HealthMonitoring
                Monitor the health of this service. Available settings function as follows: YES - Send probes to check the health of the service. NO - Do not send probes to check the health of the service. With the NO option, the appliance shows the service as UP at all times. Default value: YES. Possible values = YES, NO
            .PARAMETER ApplfowLogging
                Enable logging of AppFlow information for the specified service group. Default value: ENABLED. Possible values = ENABLED, DISABLED
            .EXAMPLE
                Add-NSServiceGroup -NSSession $Session -Name "svcgrp" -Protocol "HTTP" -CacheType SERVER -AutoscaleMode "DISABLED" 
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)] [string]$Name,
                [Parameter(Mandatory=$false)] [ValidateSet("SERVER", "TRANSPARENT", "REVERSE", "FORWARD")] [string]$CacheType,
                [Parameter(Mandatory=$false)] [ValidateSet("YES", "NO")] [string] $Cacheable,
                [Parameter(Mandatory=$false)] [ValidateSet("YES", "NO")] [string]$HealthMonitoring,
                [Parameter(Mandatory=$false)] [ValidateSet("ENABLED", "DISABLED")] [string]$AppflowLogging,
                [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Comment
            )

            Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
            $payload = @{servicegroupname=$Name}
            If ($CacheType)
            {
                If ($CacheType -eq "SERVER")
                {
                    $payload.Add("cacheable", $Cacheable)
                }
                Else
                {
                    $payload.Add("cachetype", $CacheType)
                }
            }
            If (!([string]::IsNullOrEmpty($HealthMonitoring)))
            {
                $payload.Add("healthmonitor",$HealthMonitoring)
            }
            If (!([string]::IsNullOrEmpty($AppflowLogging)))
            {
                $payload.Add("appflowlog",$AppflowLogging)
            }
            If (!([string]::IsNullOrEmpty($Comment)))
            {
                $payload.Add("comment",$Comment)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType servicegroup -Payload $payload  -Verbose:$VerbosePreference
   
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
        function Remove-NSServiceGroup {
            <#
            .SYNOPSIS
                Remove a NetScaler ServiceGroup from the NetScalerConfiguration
            .DESCRIPTION
                Remove a NetScaler ServiceGroup from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the Service.
            .EXAMPLE
                Remove-NSServer -NSSession $Session -Name $ServerName
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType servicegroup -ResourceName $Name -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
        function Get-NSServiceGroup {
            <#
            .SYNOPSIS
                Retrieve a Service from the NetScalerConfiguration
            .DESCRIPTION
                Retrieve a Service from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name for the service. Can be changed after the name is created. Minimum length = 1.
            .EXAMPLE
                Get-NSService -NSSession $Session -Name $ServiceName
            .EXAMPLE
                Get-NSService -NSSession $Session
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
            }
            Process {
                If ($Name) {
                    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType servicegroup -ResourceName $Name -Verbose:$VerbosePreference
                }
                Else {
                    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType servicegroup
                }
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
                If ($response.PSObject.Properties['servicegroup'])
                {
                    return $response.servicegroup
                }
                else
                {
                    return $null
                }
            }
        }

        function Enable-NSServiceGroup {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
                $payload = @{servicegroupname=$Name}
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType servicegroup -Payload $payload -Verbose:$VerbosePreference -Action enable
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
        function Disable-NSServiceGroup {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
                [Parameter(Mandatory=$false)][int]$Delay,
                [Parameter(Mandatory=$false)] [switch]$Graceful
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
                $GracefulState = if ($Graceful) { "YES" } else { "NO" }

                $payload = @{servicegroupname=$Name;graceful=$GracefulState}
                If ($Delay)
                {
                    $payload.Add("delay", $Delay)
                }
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType servicegroup -Payload $payload -Verbose:$VerbosePreference -Action disable
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }

        function Get-NSServiceGroupBinding {
            <#
            .SYNOPSIS
                Retrieve a Service from the NetScalerConfiguration
            .DESCRIPTION
                Retrieve a Service from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name for the service. Can be changed after the name is created. Minimum length = 1.
            .EXAMPLE
                Get-NSService -NSSession $Session -Name $ServiceName
            .EXAMPLE
                Get-NSService -NSSession $Session
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType servicegroup_binding -ResourceName $Name -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
                If ($response.PSObject.Properties['servicegroup_binding'])
                {
                    return $response.servicegroup_binding
                }
                else
                {
                    return $null
                }
            }
        }

        function New-NSServicegroupServicegroupmemberBinding {
        #Updated 20160824: Removed unknown Action parameter
            <#
            .SYNOPSIS
                Retrieve a Service from the NetScalerConfiguration
            .DESCRIPTION
                Retrieve a Service from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the service group. Minimum length = 1
            .PARAMETER IP
                IP Address.
            .PARAMETER ServerName
                Name of the server to which to bind the service group. Minimum length = 1
            .PARAMETER Weight
                Weight to assign to the servers in the service group. Specifies the capacity of the servers relative to the other servers in the load balancing configuration. The higher the weight, the higher the percentage of requests sent to the service. Minimum value = 1. Maximum value = 100
            .PARAMETER port
                server port number. Range 1 - 65535
            .PARAMETER CustomserverId
                The identifier for this IP:Port pair. Used when the persistency type is set to Custom Server ID. Default value: "None"
            .PARAMETER ServerId
                The identifier for the service. This is used when the persistency type is set to Custom Server ID.
            .PARAMETER State
                Initial state of the service group. Default value: ENABLED. Possible values = ENABLED, DISABLED
            .PARAMETER hashid
                The hash identifier for the service. This must be unique for each service. This parameter is used by hash based load balancing methods. Minimum value = 1
            .EXAMPLE
                Get-NSService -NSSession $Session -Name $ServiceName
            .EXAMPLE
                Get-NSService -NSSession $Session
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
                [Parameter(Mandatory=$true,ParameterSetName='By Name')] [string]$ServerName,
                [Parameter(Mandatory=$true,ParameterSetName='By Address')] [string]$IPAddress,
                [Parameter(Mandatory=$false)][ValidateRange(1,100)] [double]$Weight,
                [Parameter(Mandatory=$true)] [ValidateRange(1,65535)] [int]$Port,
    #            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$CustomServerId,
                [Parameter(Mandatory=$false)] [double]$ServerId,
                [Parameter(Mandatory=$true)][ValidateSet("ENABLED", "DISABLED")] [string]$State="ENABLED",
                [Parameter(Mandatory=$false)] [double]$HashId
            )
        
            Write-Verbose "$($MyInvocation.MyCommand): Enter"

            $payload = @{servicegroupname=$Name;port=$Port;state=$State}

            If ($ServerId) {$payload.Add("serverid",$ServerId)}
            If ($HashId) {$payload.Add("hashid",$HashId)}
            If ($Weight) {$payload.Add("weight",$Weight)}

            if ($PSCmdlet.ParameterSetName -eq 'By Name') {
                $payload.Add("servername",$ServerName)
            } elseif ($PSCmdlet.ParameterSetName -eq 'By Address') {
                Write-Verbose "Validating IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj)) {
                    throw "'$IPAddress' is an invalid IP address"
                }
                $payload.Add("ip",$IPAddress)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType servicegroup_servicegroupmember_binding -Payload $payload -Verbose:$VerbosePreference
   
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
        function Remove-NSServicegroupServicegroupmemberBinding {
            <#
            .SYNOPSIS
                Remove a NetScaler ServiceGroup from the NetScalerConfiguration
            .DESCRIPTION
                Remove a NetScaler ServiceGroup from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the Service.
            .EXAMPLE
                Remove-NSServer -NSSession $Session -Name $ServerName
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
                [Parameter(Mandatory=$true,ParameterSetName='By Name')] [string]$ServerName,
                [Parameter(Mandatory=$true,ParameterSetName='By Address')] [string]$IPAddress,
                [Parameter(Mandatory=$false)] [ValidateRange(1,65535)] [int]$Port
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"

                $args = @{port=$Port}
                if ($PSCmdlet.ParameterSetName -eq 'By Name') {
                    $args.Add("servername",$ServerName)
                } elseif ($PSCmdlet.ParameterSetName -eq 'By Address') {
                    Write-Verbose "Validating IP Address"
                    $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                    if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj)) {
                        throw "'$IPAddress' is an invalid IP address"
                    }
                    $args.Add("ip",$IPAddress)
                }
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType servicegroup_servicegroupmember_binding -ResourceName $Name -Arguments $args -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
        function Get-NSServicegroupServicegroupmemberBinding {
            <#
            .SYNOPSIS
                Retrieve a Service from the NetScalerConfiguration
            .DESCRIPTION
                Retrieve a Service from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name for the service. Can be changed after the name is created. Minimum length = 1.
            .EXAMPLE
                Get-NSService -NSSession $Session -Name $ServiceName
            .EXAMPLE
                Get-NSService -NSSession $Session
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType servicegroup_servicegroupmember_binding -ResourceName $Name -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
                If ($response.PSObject.Properties['servicegroup_servicegroupmember_binding'])
                {
                    return $response.servicegroup_servicegroupmember_binding
                }
                else
                {
                    return $null
                }
            }
        }
        #endregion

        #region Load Balancing - Monitors
        # Add-NSLBMonitor is part of the Citrix NITRO Module
        # Copied from Citrix's Module to ensure correct scoping of variables and functions
        # UPDATED with additional parameters
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
                Calculate the least response times for bound services. If this parameter is not enabled, the appliance does not learn the response times of the bound services. Also used for LRTM load balancing. Possible values = ENABLED, DISABLED
            .PARAMETER DestinationIPAddress
                IP address of the service to which to send probes. If the parameter is set to 0, the IP address of the server to which the monitor is bound is considered the destination IP address
            .PARAMETER StoreName
                Store Name. For monitors of type STOREFRONT, STORENAME is an optional argument defining storefront service store name. Applicable to STOREFRONT monitors
            .PARAMETER Reverse
                Mark a service as DOWN, instead of UP, when probe criteria are satisfied, and as UP instead of DOWN when probe criteria are not satisfied. Default value: NO. Possible values = YES, NO
            .EXAMPLE
                Add-NSLBMonitor -NSSession $Session -Name "Server1_Monitor" -Type "HTTP"
            .NOTES
                Copyright (c) Citrix Systems, Inc. All rights reserved.
                Copyright (c) cognition IT. All rights reserved.
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
                [Parameter(Mandatory=$false)] [string]$StoreName,
                [Parameter(Mandatory=$false)] [ValidateSet("Enabled", "Disabled")] [string]$State="Enabled",
                [Parameter(Mandatory=$false)] [switch]$Reverse
            )

            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $ReverseValue = if ($Reverse) { "YES" } else { "NO" }
            $lrtmSetting = if ($LRTM) { "ENABLED" } else { "DISABLED" }

            $payload = @{
                monitorname = $Name
                type = $Type
                lrtm = $lrtmSetting
                reverse = $ReverseValue
                state = $State
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
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType lbmonitor -Payload $payload  

            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }

        function Update-NSLBMonitor {
            <#
            .SYNOPSIS
                Update LB StoreFront monitor resource
            .DESCRIPTION
                Update LB StoreFront monitor resource
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name for the monitor
            .PARAMETER Type
                Type of monitor that you want to create
            .PARAMETER ScriptName
                Path and name of the script to execute. The script must be available on the NetScaler appliance, in the /nsconfig/monitors/ directory
            .PARAMETER LRTM
                Calculate the least response times for bound services. If this parameter is not enabled, the appliance does not learn the response times of the bound services. Also used for LRTM load balancing. Possible values = ENABLED, DISABLED
            .PARAMETER DestinationIPAddress
                IP address of the service to which to send probes. If the parameter is set to 0, the IP address of the server to which the monitor is bound is considered the destination IP address
            .PARAMETER StoreName
                Store Name. For monitors of type STOREFRONT, STORENAME is an optional argument defining storefront service store name. Applicable to STOREFRONT monitors
            .PARAMETER Reverse
                Mark a service as DOWN, instead of UP, when probe criteria are satisfied, and as UP instead of DOWN when probe criteria are not satisfied. Default value: NO. Possible values = YES, NO
            .EXAMPLE
                Update-NSLBMonitor -NSSession $Session -Name "Server1_Monitor" -Type "HTTP"
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
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
                [Parameter(Mandatory=$false)] [string]$StoreName,
                [Parameter(Mandatory=$false)] [ValidateSet("Enabled", "Disabled")] [string]$State="Enabled",
                [Parameter(Mandatory=$false)] [switch]$Reverse
            )

            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $ReverseValue = if ($Reverse) { "YES" } else { "NO" }
            $lrtmSetting = if ($LRTM) { "ENABLED" } else { "DISABLED" }

            $payload = @{
                monitorname = $Name
                type = $Type
                lrtm = $lrtmSetting
                reverse = $ReverseValue
                state = $State
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
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType lbmonitor -Payload $payload  

            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
        function Remove-NSLBMonitor{
            <#
            .SYNOPSIS
                Remove a NetScaler Monitor from the NetScalerConfiguration
            .DESCRIPTION
                Remove a NetScaler Monitor from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the Monitor.
            .EXAMPLE
                Remove-NSLBMonitor -NSSession $Session -Name $MonitorName
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
                [Parameter(Mandatory=$true)] [ValidateSet(
                "PING","TCP","HTTP","TCP-ECV","HTTP-ECV","UDP-ECV","DNS","FTP","LDNS-PING","LDNS-TCP","LDNS-DNS","RADIUS","USER","HTTP-INLINE","SIP-UDP","LOAD","FTP-EXTENDED",
                "SMTP","SNMP","NNTP","MYSQL","MYSQL-ECV","MSSQL-ECV","ORACLE-ECV","LDAP","POP3","CITRIX-XML-SERVICE","CITRIX-WEB-INTERFACE","DNS-TCP","RTSP","ARP","CITRIX-AG",
                "CITRIX-AAC-LOGINPAGE","CITRIX-AAC-LAS","CITRIX-XD-DDC","ND6","CITRIX-WI-EXTENDED","DIAMETER","RADIUS_ACCOUNTING","STOREFRONT","APPC","CITRIX-XNC-ECV","CITRIX-XDM"
                )] [string]$Type
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
                $args=@{type=$Type}
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType lbmonitor -ResourceName $Name -Arguments $args -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
        function Get-NSLBMonitor{
            <#
            .SYNOPSIS
                Retrieve a Monitor from the NetScalerConfiguration
            .DESCRIPTION
                Retrieve a Monitor from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name for the service. Can be changed after the name is created. Minimum length = 1.
            .EXAMPLE
                Get-NSLBMonitor -NSSession $Session -Name $MonitorName
            .EXAMPLE
                Get-NSLBMonitor -NSSession $Session
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
            }
            Process {
                If ($Name) {
                    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType lbmonitor -ResourceName $Name -Verbose:$VerbosePreference
                }
                Else {
                    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType lbmonitor
                }
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
                If ($response.PSObject.Properties['lbmonitor'])
                {
                    return $response.lbmonitor
                }
                else
                {
                    return $null
                }
            }
        }

    # NOTE: LBMonitor functions not complete yet!!

        function New-NSServicegroupLBMonitorBinding {
        # Created: 20160825
            <#
            .SYNOPSIS
                Bind monitor to servicegroup
            .DESCRIPTION
                Bind monitor to servicegroup
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER ServiceName
                Name of the servicegroup to which to bind monitor
            .PARAMETER MonitorName
                The monitor name
            .EXAMPLE
                New-NSServicegroupLBMonitorBinding -NSSession $Session -ServicegroupName "Server1_Service" -MonitorName "Server1_Monitor"
            .NOTES
                Copyright (c) Citrix Systems, Inc. All rights reserved.
            #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)] [string]$ServicegroupName,
                [Parameter(Mandatory=$true)] [string]$MonitorName
            )

            Write-Verbose "$($MyInvocation.MyCommand): Enter"

            $payload = @{servicegroupname=$ServicegroupName;monitor_name=$MonitorName}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType servicegroup_lbmonitor_binding -Payload $payload -Verbose:$VerbosePreference 

            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
        function Remove-NSServicegroupLBMonitorBinding{
        # Created: 20160825
            <#
            .SYNOPSIS
                Remove a NetScaler Monitor Binding from a Servicegroup
            .DESCRIPTION
                Remove a NetScaler Monitor Binding from a Servicegroup
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER ServicegroupName
                Name of the servicegroup.
            .PARAMETER MonitorName
                Name of the monitor bound to the servicegroup.
            .EXAMPLE
                Remove-NSServicegroupLBMonitorBinding -NSSession $Session -ServicegroupName $ServicegroupName -MonitorName $MonitorName
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$ServicegroupName,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$MonitorName
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
                $args=@{monitor_name=$MonitorName}
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType servicegroup_lbmonitor_binding -ResourceName $ServicegroupName -Arguments $args -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }

        function Get-NSServicegroupLBMonitorBinding{
        # Created: 20160825
            <#
            .SYNOPSIS
                Retrieve a Monitor binding for a given Servicegroup
            .DESCRIPTION
                Retrieve a Monitor binding for a given Servicegroup
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the service
            .EXAMPLE
                Get-NSServicegroupLBMonitorBinding -NSSession $Session -Name $Name
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType servicegroup_lbmonitor_binding -ResourceName $Name -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
                If ($response.PSObject.Properties['servicegroup_lbmonitor_binding'])
                {
                    return $response.servicegroup_lbmonitor_binding
                }
                else
                {
                    return $null
                }
            }
        }
    

        # Add-NSLBSFMonitor is part of the Citrix NITRO Module

        # New-NSServiceLBMonitorBinding is part of the Citrix NITRO Module
        # Copied from Citrix's Module to ensure correct scoping of variables and functions
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
                [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$ServiceName,
                [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$MonitorName,
                [Parameter(Mandatory=$false)] [string]$State,
                [Parameter(Mandatory=$false)] [int]$Weight,
                [Parameter(Mandatory=$false)] [switch]$Passive
            )

            Write-Verbose "$($MyInvocation.MyCommand): Enter"

            $payload = @{name=$ServiceName;monitor_name=$MonitorName}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType service_lbmonitor_binding -Payload $payload -Verbose:$VerbosePreference 

            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }

        function Get-NSServiceLBMonitorBinding{
        # Created: 20160825
            <#
            .SYNOPSIS
                Retrieve a Monitor binding for a given Service
            .DESCRIPTION
                Retrieve a Monitor binding for a given Service
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the service
            .EXAMPLE
                Get-NSServiceLBMonitorBinding -NSSession $Session -Name $ServiceName
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType service_lbmonitor_binding -ResourceName $Name -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
                If ($response.PSObject.Properties['service_lbmonitor_binding'])
                {
                    return $response.service_lbmonitor_binding
                }
                else
                {
                    return $null
                }
            }
        }
        #endregion

    #region Load Balancing - vServers
    # Add-NSLBVServer is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    # UPDATED with additional parameters
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
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            [Parameter(Mandatory=$true)] [ValidateSet("HTTP","FTP","TCP","UDP","SSL","SSL_BRIDGE","SSL_TCP","DTLS","NNTP","DNS","DHCPRA","ANY",
            "SIP_UDP","SIP_TCP","SIP_SSL","DNS_TCP","RTSP","PUSH","SSL_PUSH","RADIUS","RDP","MYSQL","MSSQL","DIAMETER","SSL_DIAMETER","TFTP","ORACLE",
            "SMPP","SYSLOGTCP","SYSLOGUDP")] [string]$Protocol,
            [Parameter(Mandatory=$true)] [ValidateSet("IPAddress","IPPattern","NonAdressable")] [string]$IPAddressType,
            [Parameter(Mandatory=$true,ParameterSetName='IPAddress')][ValidateScript({$IPAddressType -eq "IPAddress"})] [string]$IPAddress,
            [Parameter(Mandatory=$true,ParameterSetName='IPPattern')][ValidateScript({$IPAddressType -eq "IPPattern"})] [string]$IPPattern,
            [Parameter(Mandatory=$true,ParameterSetName='IPPattern')][ValidateScript({$IPAddressType -eq "IPPattern"})] [string]$IPMask,
            [Parameter(Mandatory=$true)] [ValidateRange(1,65535)] [int]$Port,
            [Parameter(Mandatory=$false)] [ValidateSet("SOURCEIP","COOKIEINSERT","SSLSESSION","RULE","URLPASSIVE","CUSTOMSERVERID","DESTIP","SRCIPDESTIP",
            "CALLID","RTSPSID","DIAMETER","NONE")] [string]$PersistenceType,
            [Parameter(Mandatory=$false)] [ValidateSet("ROUNDROBIN","LEASTCONNECTION","LEASTRESPONSETIME","URLHASH","DOMAINHASH","DESTINATIONIPHASH",
            "SOURCEIPHASH","SRCIPDESTIPHASH","LEASTBANDWIDTH","LEASTPACKETS","TOKEN","SRCIPSRCPORTHASH","LRTM","CALLIDHASH","CUSTOMLOAD","LEASTREQUEST",
            "AUDITLOGHASH")] [string]$LBMethod="LEASTCONNECTION",
            [Parameter(Mandatory=$false)] [ValidateRange(0,31536000)] [double]$ClientTimeout,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$Comment
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name;servicetype=$Protocol}
        }
        Process {
            if ($PSCmdlet.ParameterSetName -eq 'IPAddress') {
                Write-Verbose "Validating IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj)) {
                    throw "'$IPAddress' is an invalid IP address"
                }
                $payload.Add("ipv46",$IPAddress)
            } elseif ($PSCmdlet.ParameterSetName -eq 'IPPattern') {
                $payload.Add("ippattern",$IPPattern)
                $payload.Add("ipmask",$IPMask)
            }

            if ($Port) {$payload.Add("port",$Port)}
            if ($ClientTimeout) {$payload.Add("clttimeout",$ClientTimeout)}
            if (-not [string]::IsNullOrEmpty($PersistenceType)) {$payload.Add("persistencetype",$PersistenceType)}
            if (-not [string]::IsNullOrEmpty($LBMethod)) {$payload.Add("lbmethod",$LBMethod)}
            if (-not [string]::IsNullOrEmpty($Comment)) {$payload.Add("comment",$Comment)}

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType lbvserver -Payload $payload 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }

    function Update-NSLBVServer {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            [Parameter(Mandatory=$false)] [ValidateSet("IPAddress","IPPattern","NonAdressable")] [string]$IPAddressType,
            [Parameter(Mandatory=$false)][ValidateScript({$IPAddressType -eq "IPAddress"})] [string]$IPAddress,
            [Parameter(Mandatory=$false)][ValidateScript({$IPAddressType -eq "IPPattern"})] [string]$IPPattern,
            [Parameter(Mandatory=$false)][ValidateScript({$IPAddressType -eq "IPPattern"})] [string]$IPMask,
            [Parameter(Mandatory=$false)] [ValidateSet("SOURCEIP","COOKIEINSERT","SSLSESSION","RULE","URLPASSIVE","CUSTOMSERVERID","DESTIP","SRCIPDESTIP",
            "CALLID","RTSPSID","DIAMETER","NONE")] [string]$PersistenceType,
            [Parameter(Mandatory=$false)] [ValidateSet("ROUNDROBIN","LEASTCONNECTION","LEASTRESPONSETIME","URLHASH","DOMAINHASH","DESTINATIONIPHASH",
            "SOURCEIPHASH","SRCIPDESTIPHASH","LEASTBANDWIDTH","LEASTPACKETS","TOKEN","SRCIPSRCPORTHASH","LRTM","CALLIDHASH","CUSTOMLOAD","LEASTREQUEST",
            "AUDITLOGHASH")] [string]$LBMethod="LEASTCONNECTION",
            [Parameter(Mandatory=$false)] [ValidateRange(0,31536000)] [double]$ClientTimeout,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$Comment
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name}
        }
        Process {
            if (-not [string]::IsNullOrEmpty($IPAddress)) {
                Write-Verbose "Validating IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj)) {
                    throw "'$IPAddress' is an invalid IP address"
                }
                $payload.Add("ipv46",$IPAddress)
            } else {
                if (-not [string]::IsNullOrEmpty($IPPattern)) {$payload.Add("ippattern",$IPPattern)}
                if (-not [string]::IsNullOrEmpty($IPMask)) {$payload.Add("ipmask",$IPMask)}
            }
            if ($ClientTimeout) {$payload.Add("clttimeout",$ClientTimeout)}
            if (-not [string]::IsNullOrEmpty($PersistenceType)) {$payload.Add("persistencetype",$PersistenceType)}
            if (-not [string]::IsNullOrEmpty($LBMethod)) {$payload.Add("lbmethod",$LBMethod)}
            if (-not [string]::IsNullOrEmpty($Comment)) {$payload.Add("comment",$Comment)}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType lbvserver -Payload $payload 
        }

        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Remove-NSLBVServer {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$Name
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType lbvserver -ResourceName $Name -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Get-NSLBVServer {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$Name
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($Name){
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType lbvserver -ResourceName $Name
            }
            Else {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType lbvserver
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['lbvserver'])
            {
                return $response.lbvserver
            }
            else
            {
                return $null
            }
        }
    }

    function Enable-NSLBVServer {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$Name
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType lbvserver -Payload $payload -ResourceName $Name -Action enable -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Disable-NSLBVServer {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$Name
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType lbvserver -Payload $payload -ResourceName $Name -Action disable -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }

    function Rename-NSLBVServer {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$NewName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name;newname=$NewName}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType lbvserver -Payload $payload -Action rename
        }

        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }

    function New-NSLBVServerServicegroupBinding {
    # Updated: 20160824 - Removed unknown Action parameter
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            # Name for the virtual server.
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            # The service group name bound to the selected load balancing virtual server
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$ServiceGroupName
            # Service to bind to the virtual server.
#            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$ServiceName,
            # Integer specifying the weight of the service. Default value: 1. Minimum value = 1. Maximum value = 100
#            [Parameter(Mandatory=$false)][ValidateRange(1,100)] [int]$Weight
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name}
        }
        Process {
            if (-not [string]::IsNullOrEmpty($ServiceGroupName)) {$payload.Add("servicegroupname",$ServiceGroupName)}
#            if (-not [string]::IsNullOrEmpty($ServiceName)) {$payload.Add("servicename",$ServiceName)}
#            if ($Weight) {$payload.Add("weight",$Weight)}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType lbvserver_servicegroup_binding -Payload $payload
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Remove-NSLBVServerServicegroupBinding {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$Name,
            # The service group name bound to the selected load balancing virtual server
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$ServiceGroupName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $args=@{name=$Name;servicegroupname=$ServiceGroupName}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType lbvserver_servicegroup_binding -ResourceName $Name -Arguments $args -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Get-NSLBVServerServicegroupBinding {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$Name
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($Name){
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType lbvserver_servicegroup_binding -ResourceName $Name
            }
            Else {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType lbvserver_servicegroup_binding
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['lbvserver_servicegroup_binding'])
            {
                return $response.lbvserver_servicegroup_binding
            }
            else
            {
                return $null
            }
        }
    }

    # New-NSLBVServerServiceBinding is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    # CHANGED
    function New-NSLBVServerServiceBinding {
    # Updated: 20160824 - Removed unknown Action parameter
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
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            # Name for the virtual server.
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            # Service to bind to the virtual server.
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$ServiceName,
            # Integer specifying the weight of the service. Default value: 1. Minimum value = 1. Maximum value = 100
            [Parameter(Mandatory=$false)][ValidateRange(1,100)] [int]$Weight
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name}
        }
        Process {
            if (-not [string]::IsNullOrEmpty($ServiceName)) {$payload.Add("servicename",$ServiceName)}
            if ($Weight) {$payload.Add("weight",$Weight)}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType lbvserver_servicegroup_binding -Payload $payload
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Remove-NSLBVServerServiceBinding {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$Name,
            # The service group name bound to the selected load balancing virtual server
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$ServiceName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $args=@{name=$Name;servicename=$ServiceName}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType lbvserver_service_binding -ResourceName $Name -Arguments $args -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Get-NSLBVServerServiceBinding {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$Name
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($Name){
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType lbvserver_service_binding -ResourceName $Name
            }
            Else {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType lbvserver_service_binding
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['lbvserver_service_binding'])
            {
                return $response.lbvserver_service_binding
            }
            else
            {
                return $null
            }
        }
    }

    function New-NSLBVServerResponderPolicyBinding {
    # Updated: 20160824 - Removed unknown Action parameter
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            # Name for the virtual server
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$vServerName,
            # Name of the policy bound to the LB vserver
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$PolicyName,
            [Parameter(Mandatory=$true)] [double]$Priority,
            # Expression specifying the priority of the next policy which will get evaluated if the current policy rule evaluates to True
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$GotoPriorityExpression="END",
            # Invoke Label Type to select ("PolicyLabel", "Load Balancing Virtual Server", "Content Switching Virtual Server")
            [Parameter(Mandatory=$false)][ValidateSet("reqvserver","resvserver","policylabel")] [string]$InvokeLabelType
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"

            $payload = @{name=$vServerName;policyname=$PolicyName;priority=$Priority;bindpoint="REQUEST"}
        }
        Process {
#            if ($Invoke) {$payload.Add("invoke",$Invoke)}
            if (-not [string]::IsNullOrEmpty($GotoPriorityExpression)) {$payload.Add("gotopriorityexpression",$GotoPriorityExpression)}
            if (-not [string]::IsNullOrEmpty($InvokeLabelType)) {$payload.Add("labeltype",$InvokeLabelType)}

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType lbvserver_responderpolicy_binding -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Remove-NSLBVServerResponderPolicyBinding {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            # vServer name
            [Parameter(Mandatory=$true)] [string]$Name,
            [Parameter(Mandatory=$true)] [string]$PolicyName,
            [Parameter(Mandatory=$false)] [string]$BindPoint,
            [Parameter(Mandatory=$false)] [double]$Priority
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $args=@{policyname=$PolicyName}
            If ($Priority) {$payload.Add("priority",$Priority)}
            If (-not [string]::IsNullOrEmpty($BindPoint)){$payload.Add("bindpoint",$BindPoint)}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType lbvserver_responderpolicy_binding -ResourceName $Name -Arguments $args -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Get-NSLBVServerResponderPolicyBinding {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$Name
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType lbvserver_responderpolicy_binding -ResourceName $Name -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['lbvserver_responderpolicy_binding'])
            {
                return $response.lbvserver_responderpolicy_binding
            }
            else
            {
                return $null
            }
        }
    }

    function New-NSLBVServerRewritePolicyBinding {
    # Updated: 20160824 - Removed unknown Action parameter
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            # Name for the virtual server
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$vServerName,
            # Name of the policy bound to the LB vserver
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$PolicyName,
            # Name of the policy bound to the LB vserver
            [Parameter(Mandatory=$true)][ValidateSet("REQUEST","RESPONSE")] [string]$BindPoint="REQUEST",
            [Parameter(Mandatory=$true)] [double]$Priority,
            # Expression specifying the priority of the next policy which will get evaluated if the current policy rule evaluates to True
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$GotoPriorityExpression="END",
            # Invoke Label Type to select ("PolicyLabel", "Load Balancing Virtual Server", "Content Switching Virtual Server")
            [Parameter(Mandatory=$false)][ValidateSet("reqvserver","resvserver","policylabel")] [string]$InvokeLabelType
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$vServerName;policyname=$PolicyName;priority=$Priority;bindpoint=$BindPoint}
        }
        Process {
#            if ($Invoke) {$payload.Add("invoke",$Invoke)}
            if (-not [string]::IsNullOrEmpty($GotoPriorityExpression)) {$payload.Add("gotopriorityexpression",$GotoPriorityExpression)}
            if (-not [string]::IsNullOrEmpty($InvokeLabelType)) {$payload.Add("labeltype",$InvokeLabelType)}

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType lbvserver_rewritepolicy_binding -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Remove-NSLBVServerRewritePolicyBinding {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            # vServer name
            [Parameter(Mandatory=$true)] [string]$Name,
            [Parameter(Mandatory=$true)] [string]$PolicyName,
            [Parameter(Mandatory=$false)][ValidateSet("REQUEST","RESPONSE")] [string]$BindPoint,
            [Parameter(Mandatory=$false)] [double]$Priority
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $args=@{policyname=$PolicyName}
            If ($Priority) {$payload.Add("priority",$Priority)}
            If (-not [string]::IsNullOrEmpty($BindPoint)){$payload.Add("bindpoint",$BindPoint)}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType lbvserver_rewritepolicy_binding -ResourceName $Name -Arguments $args -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Get-NSLBVServerRewritePolicyBinding {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$Name
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType lbvserver_rewritepolicy_binding -ResourceName $Name -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['lbvserver_rewritepolicy_binding'])
            {
                return $response.lbvserver_rewritepolicy_binding
            }
            else
            {
                return $null
            }
        }
    }

    #endregion
    #endregion

    #region Traffic Management - Content Switching
    #endregion

    #region Traffic Management - DNS

    # Add-NSDnsNameServer is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    function Add-NSDnsNameServer {
    # Updated: 20160824 - Removed unknown Action parameter
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
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType dnsnameserver -Payload $payload
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }

    }

    function Update-NSDnsNameServer {
    # Updated: 20160824 - Removed unknown Action parameter
        <#
        .SYNOPSIS
            Update domain name server resource
        .DESCRIPTION
            Update domain name server resource
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER DNSServerIPAddress
            IP address of an external name server
        .PARAMETER DNSProfileName
            Name of the DNS profile to be associated with the name server. Minimum length = 1
        .EXAMPLE
            Update-NSDnsNameServer -NSSession $Session -DNSServerIPAddress $IPAddress -DNSProfileName $ProfileName
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] [string]$DNSServerIPAddress,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$DNSProfileName
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

            $payload = @{ip=$DNSServerIPAddress;dnsprofilename=$DNSProfileName}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType dnsnameserver -Payload $payload -Verbose:$VerbosePreference -ResourceName $DNSServerIPAddress
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }

    }
    # NOTE: Update gives error that DNS Profile does not exist, better make it a New-DNSServerDNSProfileBinding function
    function Remove-NSDnsNameServer {
    # Updated: 20160824 - Removed unknown Action parameter
        <#
        .SYNOPSIS
            Remove domain name server resource
        .DESCRIPTION
            Remove domain name server resource
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER DNSServerIPAddress
            IP address of an external name server
        .EXAMPLE
            Remove-NSDnsNameServer -NSSession $Session -DNSServerIPAddress $IPAddress
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
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

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType dnsnameserver -ResourceName $DNSServerIPAddress
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }

    }
    function Get-NSDnsNameServer {
        <#
        .SYNOPSIS
            Retrieve domain name server resource
        .DESCRIPTION
            Retrieve domain name server resource
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER DNSServerIPAddress
            IP address of an external name server
        .EXAMPLE
            Get-NSDnsNameServer -NSSession $Session -DNSServerIPAddress $IPAddress
        .EXAMPLE
            Get-NSDnsNameServer -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] [string]$DNSServerIPAddress
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If (!([string]::IsNullOrEmpty($DNSServerIPAddress)))
            {
                Write-Verbose "Validating IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($DNSServerIPAddress,[ref]$IPAddressObj)) {
                    throw "'$DNSServerIPAddress' is an invalid IP address"
                }
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType dnsnameserver -ResourceName $DNSServerIPAddress
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType dnsnameserver
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['dnsnameserver'])
            {
                return $response.dnsnameserver
            }
            else
            {
                return $null
            }
        }

    }

    # NOTE: Add DNS Records functions

    #endregion

    #region Traffic Management - GSLB
    #endregion

    #region Traffic Management - SSL

    # Add-NSServerCertificate is part of the Citrix NITRO Module
    # Add-NSCertKeyPair is part of the Citrix NITRO Module
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
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemfile -Payload $payload 
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
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslcertkey -Payload $payload  

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }

    # New-NSSSLVServerCertKeyBinding is part of the Citrix NITRO Module
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
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType sslvserver_sslcertkey_binding -Payload $payload  

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }

    function New-NSSSLRSAKey {
    # Created: 20160829
        <#
        .SYNOPSIS
            Create a SSL RSAkey
        .DESCRIPTION
            Create a SSL RSAkey
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER DNSServerIPAddress
            IP address of an external name server
        .EXAMPLE
            [string[]]$DNSServers = @("10.8.115.210","10.8.115.211")
            $DNSServers | Add-NSDnsNameServer -NSSession $Session 
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$KeyFileName,
            [Parameter(Mandatory=$true)] [ValidateRange(512,4096)] [int]$KeySize=1024,
            [Parameter(Mandatory=$false)] [ValidateSet("3","F4")] [string]$PublicExponent="F4",
            [Parameter(Mandatory=$false)] [ValidateSet("PEM","DER")] [string]$KeyFormat,
            [Parameter(Mandatory=$false)] [ValidateSet("DES","DES3","None")] [string]$PEMEncodingAlgorithm,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$PEMPassphrase
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{keyfile=$KeyFileName;bits=$KeySize}

            if ($PublicExponent) {
                $payload.Add("exponent",$PublicExponent)
            }
            if ($KeyFormat) {
                $payload.Add("keyform",$KeyFormat)
            }
            if ($PEMPassphrase) {
                $payload.Add("password",$PEMPassphrase)
            }
            If ($PEMEncodingAlgorithm -eq "DES")
            {
                $payload.Add("des",$true)
            }
            If ($PEMEncodingAlgorithm -eq "DES3")
            {
                $payload.Add("des3",$true)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslrsakey -Payload $payload -Action create -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }


    }
    function New-NSSSLCertificateSigningRequest {
    # Created: 20160829
        <#
        .SYNOPSIS
            Create a Certificate Signing Request (CSR)
        .DESCRIPTION
            Create a Certificate Signing Request (CSR)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER DNSServerIPAddress
            IP address of an external name server
        .EXAMPLE
            [string[]]$DNSServers = @("10.8.115.210","10.8.115.211")
            $DNSServers | Add-NSDnsNameServer -NSSession $Session 
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$RequestFileName,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$KeyFile,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$FipsKeyName,
            [Parameter(Mandatory=$false)] [ValidateSet("PEM","DER")] [string]$KeyFormat,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$PEMPassphrase,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$CountryName,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$StateName,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$OrganizationName,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$OrganizationUnitName,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$LocalityName,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$CommonName,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$EmailAddress,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$ChallengePassword,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$CompanyName,
            [Parameter(Mandatory=$false)] [ValidateSet("SHA1","SHA256")] [string]$DigestMethod
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{reqfile=$RequestFileName;countryname=$CountryName;statename=$StateName;organizationname=$OrganizationName}

            if ($KeyFile) {
                $payload.Add("keyfile",$KeyFile)
            }
            if ($FipsKeyName) {
                $payload.Add("fipskeyname",$FipsKeyName)
            }
            if ($KeyFormat) {
                $payload.Add("keyform",$KeyFormat)
            }
            if ($OrganizationUnitName) {
                $payload.Add("organizationunitname",$OrganizationUnitName)
            }
            If ($DigestMethod)
            {
                $payload.Add("digestmethod",$DigestMethod)
            }
            If ($PEMPassphrase)
            {
                $payload.Add("pempassphrase",$PEMPassphrase)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslcertreq -Payload $payload -Action create -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }

    function Add-NSSSLCertKey {
    # Created: 20160829
        <#
        .SYNOPSIS
            Install a SSL certificate key pair
        .DESCRIPTION
            Install a SSL certificate key pair
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertKeyName
            Name for the certificate and private-key pair
        .PARAMETER CertPath
            Path to the X509 certificate file that is used to form the certificate-key pair
        .PARAMETER KeyPath
            path to the optional private-key file that is used to form the certificate-key pair
        .PARAMETER CertKeyFormat
            Input format of the certificate and the private-key files, allowed values are "PEM" and "DER", default to "PEM"
        .PARAMETER Password
            Pass phrase used to encrypt the private-key. Required when adding an encrypted private-key in PEM format
        .SWITCH ExpiryMonitor
            Determines whether the expiration of a certificate needs to be monitored
        .PARAMETER NotificationPeriod
            How many days before the certificate is expiring a notification is shown
        .EXAMPLE
            Add-NSCertKeyPair -NSSession $Session -CertKeyName "*.xd.local" -CertPath "/nsconfig/ssl/ns.cert" -KeyPath "/nsconfig/ssl/ns.key" -CertKeyFormat PEM -Password "luVJAUxtmUY=" -ExpiryMonitor -NotificationPeriod 25
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$CertKeyName,
            [Parameter(Mandatory=$true)] [string]$CertPath,
            [Parameter(Mandatory=$false)] [string]$KeyPath,
            [Parameter(Mandatory=$true)] [ValidateSet("PEM","DER","PFX")] [string]$CertKeyFormat="PEM",
            [Parameter(Mandatory=$false)] [string]$Password,
            [Parameter(Mandatory=$false)] [switch]$ExpiryMonitor,
            [Parameter(Mandatory=$false)] [ValidateRange(10,100)][int]$NotificationPeriod=30
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $ExpiryMonitorValue = if ($ExpiryMonitor) { "ENABLED" } else { "DISABLED" }

        $payload = @{certkey=$CertKeyName;cert=$CertPath;inform=$CertKeyFormat;expirymonitor=$ExpiryMonitorValue}
        if ($NotificationPeriod) {
            $payload.Add("notificationperiod",$NotificationPeriod)
        }
        If (!([string]::IsNullOrEmpty($KeyPath)))
        {
            $payload.Add("key",$KeyPath)
        }
        if ($CertKeyFormat -eq "PEM" -and $Password) {
            $payload.Add("passplain",$Password)
        }
        if ($CertKeyFormat -eq "PFX" -and $Password) {
            $payload.Add("passplain",$Password)
        }
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslcertkey -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Remove-NSSSLCertKey {
    # Created: 20160906
        <#
        .SYNOPSIS
            Remove a SSL Cert Key pair
        .DESCRIPTION
            Remove a SSL Cert Key pair
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertKeyName
            Name for the certificate and private-key pair
        .EXAMPLE
            Remove-NSSSLCertKey -NSSession $Session -CertKeyName "*.xd.local"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$CertKeyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType sslcertkey -ResourceName $CertKeyName -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Get-NSSSLCertKey {
    # Created: 20160905
        <#
        .SYNOPSIS
            Retrieve certificate key resource(s) from the NetScaler configuration
        .DESCRIPTION
            Retrieve certificate key resource(s) from the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertName
            Name of the certificate key resource to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSSLCertKey -NSSession $Session -CertName $certname
        .EXAMPLE
            Get-NSSSLCertKey -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$CertName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        If (-not [string]::IsNullOrEmpty($CertName)) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType sslcertkey -ResourceName $CertName -Verbose:$VerbosePreference
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType sslcertkey -Verbose:$VerbosePreference
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['sslcertkey'])
        {
            return $response.sslcertkey
        }
        else
        {
            return $null
        }
    }

    function Add-NSSSLCertKeyLink {
    # Created: 20160829
        <#
        .SYNOPSIS
            Link a SSL certificate to another SSL certificate
        .DESCRIPTION
            Link a SSL certificate to another SSL certificate
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertKeyName
            Name for the certificate and private-key pair
        .PARAMETER LinkCertKeyName
            Name for the Linked certificate and private-key pair
        .EXAMPLE
            Add-NSCertKeyPair -NSSession $Session -CertKeyName "wildcard" -LinkCertKeyName "rootCA"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$CertKeyName,
            [Parameter(Mandatory=$true)] [string]$LinkCertKeyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload = @{certkey=$CertKeyName;linkcertkeyname=$LinkCertKeyName}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslcertkey -Payload $payload -Action link -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Remove-NSSSLCertKeyLink {
    # Created: 20160829
        <#
        .SYNOPSIS
            Remove the cert link for a SSL certificate
        .DESCRIPTION
            Remove the cert link for a SSL certificate
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertKeyName
            Name for the certificate and private-key pair
        .EXAMPLE
            Add-NSCertKeyPair -NSSession $Session -CertKeyName "wildcard"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$CertKeyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload = @{certkey=$CertKeyName}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslcertkey -Payload $payload -Action unlink -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Get-NSSSLCertKeyLink {
    # Created: 20160906
        <#
        .SYNOPSIS
            Retrieve certificate links
        .DESCRIPTION
            Retrieve certificate links
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertKeyName
            Name of the file to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSSLCertKeyLink -NSSession $Session -CertKeyName $name
        .EXAMPLE
            Get-NSSSLCertKeyLink -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$CertKeyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

#        If (-not [string]::IsNullOrEmpty($CertKeyName)) {
#            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType sslcertlink -ResourceName $CertKeyName -Verbose:$VerbosePreference
#        }
#        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType sslcertlink -Verbose:$VerbosePreference
#        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['sslcertlink'])
        {
            return $response.sslcertlink
        }
        else
        {
            return $null
        }
    }

    function Add-NSSystemFile {    
    # Created: 20160905
<#
        .SYNOPSIS
            Uploading a file to the NetScaler Appliance
        .DESCRIPTION
            Uploading a file to the provided folder on the NetScaler Appliance. Destination file names are the same as source file names.
            N.B. This requires the Nitro Rest API version 10.5 or higher.
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER PathToFile
            Full path to the the file
        .PARAMETER NetScalerFolder
            Full path to the folder on the NetScaler Appliance to upload the file to
        .EXAMPLE
            Send two lfiles to NetScaler appliance
            $licfiles = @("C:\NSLicense\CAG_Enterprise_VPX_2012.lic","C:\NSLicense\CAGU-Hostname_10000CCU_sslvpn-sg.lic")
            $licfiles | Send-NSLicense -NSSession $session -NetScalerFolder "/nsconfig/license"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession, 
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] [string]$PathToFile,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$NetScalerFolder

        )
        Begin {        
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            Write-Verbose "Upload file '$PathToFile' to NetScaler '$($NSSession.Endpoint)$NetScalerFolder'"
            $FileName = Split-Path -Path $PathToFile -Leaf
            # Parameter explained: -Leaf     => Indicates that this cmdlet returns only the last item or container in the path. For example, in the path C:\Test\Logs\Pass1.log, it returns only Pass1.log.
        
            $FileContent = Get-Content $PathToFile -Encoding "Byte"
            $FileContentBase64 = [System.Convert]::ToBase64String($FileContent)

            $payload = @{filename=$FileName;filecontent=$FileContentBase64;filelocation=$NetScalerFolder;fileencoding="BASE64"}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemfile -Payload $payload
        } 
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }   
    }
    function Remove-NSSystemFile {
    # Created: 20160905
        <#
        .SYNOPSIS
            Delete a file from a NetScaler Appliance
        .DESCRIPTION
            Delete a file from a NetScaler Appliance
        .PARAMETER NetScalerFolder
            Full path of the folder that hosts the file to be removed from the NetScaler Appliance
        .PARAMETER FileName
            Name of the file to be removed from the NetScaler Appliance
        .EXAMPLE
            Remove-NSSystemFile -NSSession $session -NetScalerFolder "/nsconfig/license/" -FileName $filename
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession, 
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$NetScalerFolder,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$FileName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $args = @{filelocation=$NetScalerFolder}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType systemfile -ResourceName $FileName -Arguments $args -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
    function Get-NSSystemFile {
    # Created: 20160905
        <#
        .SYNOPSIS
            Retrieve system file resource(s) from the NetScaler configuration
        .DESCRIPTION
            Retrieve system file resource(s) from the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER FileName
            Name of the file to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSystemFile -NSSession $Session -NetScalerFolder $folder -FileName $filename
        .EXAMPLE
            Get-NSSystemGroup -NSSession $Session -NetScalerFolder $folder
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$NetScalerFolder,
            [Parameter(Mandatory=$false)] [string]$FileName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $args = @{filelocation=$NetScalerFolder}

        If (-not [string]::IsNullOrEmpty($FileName)) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemfile -ResourceName $FileName -Arguments $args -Verbose:$VerbosePreference
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemfile -Arguments $args  -Verbose:$VerbosePreference
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['systemfile'])
        {
            return $response.systemfile
        }
        else
        {
            return $null
        }
    }

    function Add-NSSSLVServerCertKeyBinding {
    # Created: 20160912
        <#
        .SYNOPSIS
            Bind a SSL certificate to a NetScaler vServer
        .DESCRIPTION
            Bind a SSL certificate to a NetScaler vServer
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER vServerName
            Name of the NetScaler vServer to bind the certificate to
        .PARAMETER CertKeyName
            Name of the certificate-key pair to bind to the vServer
        .EXAMPLE
            Add-NSSSLVServerCertKeyBinding -NSSession $Session -VServerName $name -CertKeyName "wildcard"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$VServerName,
            [Parameter(Mandatory=$true)] [string]$CertKeyName,
            [Parameter(Mandatory=$false)] [ValidateSet("Mandatory","Optional")] [string]$CRLCheck,
            [Parameter(Mandatory=$false)] [ValidateSet("Mandatory","Optional")] [string]$OCSPCheck,
            [Parameter(Mandatory=$false)] [switch]$CA,
            [Parameter(Mandatory=$false)] [switch]$SkipCAName,
            [Parameter(Mandatory=$false)] [switch]$SNICert
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"
        $CAValue = if ($CA) { "true" } else { "false" }
        $SkipCANameValue = if ($SkipCAName) { "true" } else { "false" }
        $SNICertValue = if ($SNICert) { "true" } else { "false" }

        $payload = @{vservername=$VServerName;certkeyname=$CertKeyName;ca=$CAValue;skipcaname=$SkipCANameValue;snicert=$SNICertValue}

        If (!([string]::IsNullOrEmpty($CRLCheck)))
        {
            $payload.Add("crlcheck",$CRLCheck)
        }
        If (!([string]::IsNullOrEmpty($OCSPCheck)))
        {
            $payload.Add("ocspcheck",$OCSPCheck)
        }

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType sslvserver_sslcertkey_binding -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Remove-NSSSLVServerCertKeyBinding {
    # Created: 20160912
        <#
        .SYNOPSIS
            Unbind a SSL certificate to a NetScaler vServer
        .DESCRIPTION
            Unbind a SSL certificate to a NetScaler vServer
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER vServerName
            Name of the NetScaler vServer to bind the certificate to
        .PARAMETER CertKeyName
            Name of the certificate-key pair to bind to the vServer
        .EXAMPLE
            Remove-NSSSLVServerCertKeyBinding -NSSession $Session -VServerName $name -CertKeyName "wildcard"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$VServerName,
            [Parameter(Mandatory=$false)] [string]$CertKeyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $args = @{}
        If (!([string]::IsNullOrEmpty($CertKeyName)))
        {
        $args.Add("certkeyname",$CertKeyName)
        }

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType sslvserver_sslcertkey_binding -ResourceName $VServerName -Arguments $args -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
    function Get-NSSSLVServerCertKeyBinding {
    # Created: 20160912
        <#
        .SYNOPSIS
            Retrieve certificate links
        .DESCRIPTION
            Retrieve certificate links
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertKeyName
            Name of the file to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSSLCertKeyLink -NSSession $Session -CertKeyName $name
        .EXAMPLE
            Get-NSSSLCertKeyLink -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$VServerName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        If (-not [string]::IsNullOrEmpty($VServerName)) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType sslvserver_sslcertkey_binding -ResourceName $VServerName -Verbose:$VerbosePreference
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType sslvserver_sslcertkey_binding -Verbose:$VerbosePreference
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['sslvserver_sslcertkey_binding'])
        {
            return $response.sslvserver_sslcertkey_binding
        }
        else
        {
            return $null
        }
    }

    #endregion
#endregion

#region NetScaler Gateway

    # Add-NSVPNVServer is part of the Citrix NITRO Module
    # New-NSVPNVServerAuthLDAPPolicyBinding is part of the Citrix NITRO Module
    # Add-NSVPNSessionAction is part of the Citrix NITRO Module
    # Add-NSVPNSessionPolicy is part of the Citrix NITRO Module
    # New-NSVPNVServerSessionPolicyBinding is part of the Citrix NITRO Module
    # New-NSVPNVServerSTAServerBinding is part of the Citrix NITRO Module

    # Set-NSSFStore is part of the Citrix NITRO Module

#endregion

#endregion

