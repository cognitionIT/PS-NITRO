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
