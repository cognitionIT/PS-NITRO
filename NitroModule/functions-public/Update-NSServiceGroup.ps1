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
