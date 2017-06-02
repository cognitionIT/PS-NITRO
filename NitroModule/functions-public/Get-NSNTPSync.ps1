    function Get-NSNTPSync {
        <#
        .SYNOPSIS
            Retrieve the NTP Synchronization setting from the NetScaler Configuration
        .DESCRIPTION
            Retrieve the NTP Synchronization setting from the NetScaler Configuration
        .EXAMPLE
            Get-NSNTPSync -NSSession $Session
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
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType ntpsync -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['ntpsync'])
            {
                return $response.ntpsync
            }
            else
            {
                return $null
            }
        }
    }
