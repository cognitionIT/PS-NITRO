    # NOTE: Update gives error that DNS Profile does not exist, better make it a New-DNSServerDNSProfileBinding function
    function Update-NSDnsNameServer {
    # Updated: 20160824 - Removed unknown Action parameter
        <#
        .SYNOPSIS
            Update domain name server resource
        .DESCRIPTION
            Update domain name server resource
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER DNSServerIPAddress
            IP address of an external name server
        .PARAMETER DNSProfileName
            Name of the DNS profile to be associated with the name server. Minimum length = 1
        .EXAMPLE
            Update-NSDnsNameServer -NSSession $Session -DNSServerIPAddress $IPAddress -DNSProfileName $ProfileName
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] [string]$DNSServerIPAddress,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$DNSProfileName
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

            $payload = @{ip=$DNSServerIPAddress;dnsprofilename=$DNSProfileName}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType dnsnameserver -Payload $payload -Verbose:$VerbosePreference -ResourceName $DNSServerIPAddress
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }

    }
