    # Created: 20160829
    function New-NSSSLRSAKey {
        <#
        .SYNOPSIS
            Create a SSL RSAkey
        .DESCRIPTION
            Create a SSL RSAkey
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER KeyFileName
            Name of and, optionally, path to the private key used to create the certificate signing request, which then becomes part of the certificate-key pair. The private key can be either an RSA or a DSA key. The key must be present in the appliance's local storage. /nsconfig/ssl is the default path.
        .PARAMETER KeySize
            Size, in bits, of the RSA key. Minimum value = 512. Maximum value = 4096
        .PARAMETER PublicExponent
            Public exponent for the RSA key. The exponent is part of the cipher algorithm and is required for creating the RSA key.
            Default value: F4. Possible values = 3, F4
        .PARAMETER KeyFormat
            Format in which the key is stored on the appliance. Default value: PEM. Possible values = DER, PEM.
        .PARAMETER PEMEncodingAlgorithm
            IP address of an external name server
        .PARAMETER PEMPassphrase
            Password for the PEM certificate file
        .EXAMPLE
            New-NSSSLRSAKey -NSSession $Session -KeyFileName selfsigned.key -KeySize 2048 -KeyFormat PEM -PEMEncodingAlgorithm DES3 -PEMPassPhrase "password"
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
