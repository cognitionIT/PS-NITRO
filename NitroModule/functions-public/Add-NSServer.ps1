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
