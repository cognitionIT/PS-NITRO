    function Get-NSNTPStatus {
        <#
        .SYNOPSIS
            Retrieve the NTP status from the NetScaler Configuration
        .DESCRIPTION
            Retrieve the NTP status from the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Get-NSNTPStatus -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType ntpstatus -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['ntpstatus'])
            {
                return $response.ntpstatus
            }
            else
            {
                return $null
            }
        }
    }
