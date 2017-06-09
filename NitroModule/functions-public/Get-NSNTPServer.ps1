    function Get-NSNTPServer {
        <#
        .SYNOPSIS
            Retrieve a NetScaler NTP Server Configuration
        .DESCRIPTION
            Retrieve a NetScaler NTP Server Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ServerName
            Fully qualified domain name or IPv4 address of the NTP server.
        .EXAMPLE
            Get-NSNTPServer -NSSession $Session -ServerName "10.108.151.2"
        .EXAMPLE
            Get-NSNTPServer -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$ServerName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($ServerName){
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType ntpserver -ResourceName $ServerName -Verbose:$VerbosePreference
            }
            Else {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType ntpserver -Verbose:$VerbosePreference
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['ntpserver'])
            {
                return $response.ntpserver
            }
            else
            {
                return $null
            }
        }
    }
