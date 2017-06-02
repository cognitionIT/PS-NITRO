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
