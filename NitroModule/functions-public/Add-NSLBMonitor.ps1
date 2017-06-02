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
