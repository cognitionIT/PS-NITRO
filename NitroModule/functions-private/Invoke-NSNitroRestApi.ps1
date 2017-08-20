    # Invoke-NSNitroRestApi is UPDATED (provided by Citrix)
    # [adjusted for beter DELETE function support]
    # 20160117: Adjusted to ensure DELETE methods can produce output as well as use the Arguments parameter
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
        .PARAMETER Arguments
            Payload for the arguments that can be added to the REST API call when the HTTP Method GET or DELETE is used.
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
