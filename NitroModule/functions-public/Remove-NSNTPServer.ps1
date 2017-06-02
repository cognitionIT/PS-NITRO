    function Remove-NSNTPServer {
        <#
        .SYNOPSIS
            Delete a NetScaler NTP Server Configuration
        .DESCRIPTION
            Delete a NetScaler NTP Server Configuration
        .PARAMETER ServerName
            Fully qualified domain name or IPv4 address of the NTP server.
        .EXAMPLE
            Delete-NSNTPServer -NSSession $Session -ServerName "10.108.151.2"
        .EXAMPLE
            Delete-NSNTPServer -NSSession $Session -ServerName "ntp.server.com"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$ServerName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType ntpserver -ResourceName $ServerName -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
