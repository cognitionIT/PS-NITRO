    function Update-NSNTPServer {
        <#
        .SYNOPSIS
            Update a NetScaler NTP Server Configuration
        .DESCRIPTION
            Update a NetScaler NTP Server Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ServerIP
            IPv4 address of the NTP Server. Minimum length = 1
        .PARAMETER ServerName
            Fully qualified domain name of the NTP server.
        .PARAMETER MinPoll
            Minimum time after which the NTP server must poll the NTP messages. In seconds, expressed as a power of 2. Minimum value = 4. Maximum value = 17.
        .PARAMETER MaxPoll
            Maximum time after which the NTP server must poll the NTP messages. In seconds, expressed as a power of 2. Minimum value = 4. Maximum value = 17.
        .PARAMETER Key
            Key to use for encrypting authentication fields. All packets sent to and received from the server must include authentication fields encrypted by using this key. To require authentication for communication with the server, you must set either the value of this parameter or the autokey parameter. Minimum value = 1. Maximum value = 65534.
        .SWITCH Preferred
            Preferred NTP server. The NetScaler appliance chooses this NTP server for time synchronization among a set of correctly operating hosts. Default value: NO. Possible values = YES, NO
        .EXAMPLE
            Update-NSNTPServer -NSSession $Session -NTPServerIP "10.108.151.2" -MinPoll 5 -MaxPoll 10
        .EXAMPLE
            Update-NSNTPServer -NSSession $Session -NTPServerName "ntp.server.com" -Preferred        
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true,ParameterSetName='Address')] [string]$ServerIP,
            [Parameter(Mandatory=$true,ParameterSetName='Name')] [string]$ServerName,
            [Parameter(Mandatory=$false)] [ValidateRange(4,17)] [int]$MinPoll,
            [Parameter(Mandatory=$false)] [ValidateRange(4,17)] [int]$MaxPoll,
            [Parameter(Mandatory=$false)] [ValidateRange(1,65534)] [int]$Key,
            [Parameter(Mandatory=$false)] [switch]$Preferred
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{}
        }
        Process {
            $PreferredState = if ($Preferred) { "YES" } else { "NO" }
            $payload.Add("preferredntpserver",$PreferredState)        

            if ($PSCmdlet.ParameterSetName -eq 'Address') {
                Write-Verbose "Validating NTP Server IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($ServerIP,[ref]$IPAddressObj)) {
                    throw "'$ServerIP' is an invalid IP address"
                }
                $payload.Add("serverip",$ServerIP)
            } elseif ($PSCmdlet.ParameterSetName -eq 'Name') {
                $payload.Add("servername",$ServerName)
            }
            if ($MinPoll) {
                $payload.Add("minpoll",$MinPoll)
            }
            if ($MaxPoll) {
                $payload.Add("maxpoll",$MaxPoll)
            }
            if ($Key) {
                $payload.Add("key",$Key)
            }
            else {
                $payload.Add("autokey",$true)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType ntpserver -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
