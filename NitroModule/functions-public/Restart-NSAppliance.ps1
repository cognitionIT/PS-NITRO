    # Restart-NSAppliance is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    function Restart-NSAppliance {
        <#
        .SYNOPSIS
            Restart NetScaler Appliance, with an option to save NetScaler Config File before rebooting
        .DESCRIPTION
            Restart NetScaler Appliance, with an option to save NetScaler Config File before rebooting
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER SaveNSConfig
            Switch Parameter to save NetScaler Config file before rebooting.
        .PARAMETER WarmReboot
            Switch Parameter to perform warm reboot of the NetScaler appliance
        .PARAMETER Wait
            Switch Parameter to wait after reboot until Nitro REST API is online
        .PARAMETER WaitTimeout
            Timeout in seconds for the wait after reboot
        .EXAMPLE
            Save NetScaler Config file and restart NetScaler VPX
            Restart-NSAppliance -NSIP 10.108.151.1 -SaveNSConfig -WebSession $session
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [switch]$SaveNSConfig,
            [Parameter(Mandatory=$false)] [switch]$WarmReboot,
            [Parameter(Mandatory=$false)] [switch]$Wait,
            [Parameter(Mandatory=$false)] [int]$WaitTimeout=900
        )
        Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
        if ($SaveNSConfig) {
            Save-NSConfig -NSSession $NSSession
        }
    
        $canWait = $true
        $endpoint = $NSSession.Endpoint
        $ping = New-Object System.Net.NetworkInformation.Ping

        $payload = @{warm=$WarmReboot.ToBool()}
        $result = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType reboot -Payload $payload -Action reboot

        if ($Wait) {
            Write-Verbose "Start waiting process..."
            $waitStart = Get-Date
            Write-Verbose "Trying to ping until unreachable to ensure reboot process"
            while ($canWait -and $($ping.Send($endpoint,2000)).Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                if ($($(Get-Date) - $waitStart).TotalSeconds -gt $WaitTimeout) {
                    $canWait = $false
                    break
                } else {
                    Write-Verbose "Still reachable. Pinging again..."
                    Start-Sleep -Seconds 1
                }
            } 

            if ($canWait) {
                Write-Verbose "Trying to reach Nitro REST API to test connectivity..."       
                while ($canWait) {
                    $connectTestError = $null
                    $response = $null
                    try {
                        $response = Invoke-RestMethod -Uri "$($Script:NSURLProtocol)://$endpoint/nitro/v1/config" -Method GET -ContentType application/json -ErrorVariable connectTestError
                    }
                    catch {
                        if ($connectTestError) {
                            if ($connectTestError.InnerException.Message -eq "The remote server returned an error: (401) Unauthorized.") {
                                break
                            } elseif ($($(Get-Date) - $waitStart).TotalSeconds -gt $WaitTimeout) {
                                $canWait = $false
                                break
                            } else {
                                Write-Verbose "Nitro REST API is not responding. Trying again..."
                                Start-Sleep -Seconds 1
                            }
                        }
                    }
                    if ($response) {
                        break
                    }
                }
            }

            if ($canWait) {
                Write-Verbose "NetScaler appliance is back online."
            } else {
                throw "Timeout expired. Unable to determine if NetScaler appliance is back online."
            }
        }

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
