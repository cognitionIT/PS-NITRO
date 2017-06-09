    # Updated: 20160824 - Removed unknown Action parameter
    function Remove-NSDnsNameServer {
        <#
        .SYNOPSIS
            Remove domain name server resource
        .DESCRIPTION
            Remove domain name server resource
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER DNSServerIPAddress
            IP address of an external name server
        .EXAMPLE
            Remove-NSDnsNameServer -NSSession $Session -DNSServerIPAddress $IPAddress
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] [string]$DNSServerIPAddress
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            Write-Verbose "Validating IP Address"
            $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
            if (-not [System.Net.IPAddress]::TryParse($DNSServerIPAddress,[ref]$IPAddressObj)) {
                throw "'$DNSServerIPAddress' is an invalid IP address"
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType dnsnameserver -ResourceName $DNSServerIPAddress
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }

    }
