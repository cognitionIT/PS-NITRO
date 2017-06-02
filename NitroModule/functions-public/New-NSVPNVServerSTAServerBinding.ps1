    # New-NSVPNVServerSTAServerBinding is part of the Citrix NITRO Module
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
