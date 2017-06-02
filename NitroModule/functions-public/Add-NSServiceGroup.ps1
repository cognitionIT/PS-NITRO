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
