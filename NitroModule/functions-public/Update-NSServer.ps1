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
