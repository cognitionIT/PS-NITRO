    function Get-NSIPResource {
        <#
        .SYNOPSIS
            Retrieve NetScaler IP resource(s)
        .DESCRIPTION
            Retrieve NetScaler IP resource(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER IPAddress
            IPv4 address that will be retrieved from the NetScaler appliance.
        .EXAMPLE
            Get-NSIPResource -NSSession $Session -IPAddress "10.108.151.2"
        .EXAMPLE
            Get-NSIPResource -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false,ValueFromPipeline=$true)] [string]$IPAddress
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"

        }
        Process {
            If ($IPAddress) {
                Write-Verbose "Validating IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj) -or $IPAddressObj.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
                    throw "'$IPAddress' is an invalid IPv4 address"
                }
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsip -ResourceName $IPAddress -Action get
            }
            Else
            {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsip -Action get
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['nsip'])
            {
                return $response.nsip
            }
            else
            {
                return $null
            }
        }
    }
