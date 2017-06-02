    function Remove-NSIPResource {
        <#
        .SYNOPSIS
            Delete NetScaler IP resource(s)
        .DESCRIPTION
            Delete NetScaler IP resource(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER IPAddress
            IPv4 address that will be removed from the NetScaler appliance.
        .EXAMPLE
            Delete Subnet IP
            Remove-NSIPResource -NSSession $Session -IPAddress "10.108.151.2"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true,ValueFromPipeline=$true)] [string]$IPAddress
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"

        }
        Process {
            Write-Verbose "Validating IP Address"
            $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
            if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj) -or $IPAddressObj.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
                throw "'$IPAddress' is an invalid IPv4 address"
            }
        
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType nsip -ResourceName $IPAddress -Action delete
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
