    function Get-NSDnsNameServer {
        <#
        .SYNOPSIS
            Retrieve domain name server resource
        .DESCRIPTION
            Retrieve domain name server resource
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER DNSServerIPAddress
            IP address of an external name server
        .EXAMPLE
            Get-NSDnsNameServer -NSSession $Session -DNSServerIPAddress $IPAddress
        .EXAMPLE
            Get-NSDnsNameServer -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] [string]$DNSServerIPAddress
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If (!([string]::IsNullOrEmpty($DNSServerIPAddress)))
            {
                Write-Verbose "Validating IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($DNSServerIPAddress,[ref]$IPAddressObj)) {
                    throw "'$DNSServerIPAddress' is an invalid IP address"
                }
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType dnsnameserver -ResourceName $DNSServerIPAddress
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType dnsnameserver
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['dnsnameserver'])
            {
                return $response.dnsnameserver
            }
            else
            {
                return $null
            }
        }

    }
