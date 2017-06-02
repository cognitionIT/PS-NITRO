    function New-NSSSLRSAKey {
    # Created: 20160829
        <#
        .SYNOPSIS
            Create a SSL RSAkey
        .DESCRIPTION
            Create a SSL RSAkey
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER DNSServerIPAddress
            IP address of an external name server
        .EXAMPLE
            [string[]]$DNSServers = @("10.8.115.210","10.8.115.211")
            $DNSServers | Add-NSDnsNameServer -NSSession $Session 
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$KeyFileName,
            [Parameter(Mandatory=$true)] [ValidateRange(512,4096)] [int]$KeySize=1024,
            [Parameter(Mandatory=$false)] [ValidateSet("3","F4")] [string]$PublicExponent="F4",
            [Parameter(Mandatory=$false)] [ValidateSet("PEM","DER")] [string]$KeyFormat,
            [Parameter(Mandatory=$false)] [ValidateSet("DES","DES3","None")] [string]$PEMEncodingAlgorithm,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$PEMPassphrase
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{keyfile=$KeyFileName;bits=$KeySize}

            if ($PublicExponent) {
                $payload.Add("exponent",$PublicExponent)
            }
            if ($KeyFormat) {
                $payload.Add("keyform",$KeyFormat)
            }
            if ($PEMPassphrase) {
                $payload.Add("password",$PEMPassphrase)
            }
            If ($PEMEncodingAlgorithm -eq "DES")
            {
                $payload.Add("des",$true)
            }
            If ($PEMEncodingAlgorithm -eq "DES3")
            {
                $payload.Add("des3",$true)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslrsakey -Payload $payload -Action create -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }


    }
