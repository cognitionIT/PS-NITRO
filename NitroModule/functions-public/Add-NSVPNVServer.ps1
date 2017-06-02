    # Add-NSVPNVServer is part of the Citrix NITRO Module
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
