    # Add-NSServerCertificate is part of the Citrix NITRO Module
    function Add-NSServerCertificate {
        <#
        .SYNOPSIS
            Add NetScaler Appliance Server Certificate
        .DESCRIPTION
            Add NetScaler Appliance Server Certificate by:
            -Creating the private RSA key
            -Creating the CSR
            -Downloading the CSR
            -Requesting the certificate
            -Uploading the certificate
            -Created the cert/key pair

            This requires the Nitro Rest API version 10.5 or higher.
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CAName
            The FQDN of the Certification Authority host and Certification Authority name in the form CAHostNameFQDN\CAName
        .PARAMETER CommonName
            Fully qualified domain name for the company or web site.
            The common name must match the name used by DNS servers to do a DNS lookup of your server.
            Most browsers use this information for authenticating the server's certificate during the SSL handshake.
            If the server name in the URL does not match the common name as given in the server certificate, the browser terminates the SSL handshake or prompts the user with a warning message.
            Do not use wildcard characters, such as asterisk (*) or question mark (?), and do not use an IP address as the common name.
            The common name must not contain the protocol specifier or .
        .PARAMETER OrganizationName
            Name of the organization that will use this certificate.
            The organization name (corporation, limited partnership, university, or government agency) must be registered with some authority at the national, state, or city level.
            Use the legal name under which the organization is registered.
            Do not abbreviate the organization name and do not use the following characters in the name: Angle brackets (< >) tilde (~), exclamation mark, at (@), pound (#), zero (0), caret (^), asterisk (*), forward slash (/), square brackets ([ ]), question mark (?).
        .PARAMETER CountryName
            Two letter ISO code for your country. For example, US for United States.
        .PARAMETER StateName
            Full name of the state or province where your organization is located. Do not abbreviate.
        .PARAMETER KeyFileBits
            Size, in bits, of the private key.
        .EXAMPLE
             Add-NSServerCertificate -NSSession $Session
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$CAName,
            [Parameter(Mandatory=$true)] [ValidateLength(1,63)] [string]$CommonName,
            [Parameter(Mandatory=$true)] [ValidateLength(1,63)] [string]$OrganizationName,
            [Parameter(Mandatory=$true)] [ValidateLength(2,2)] [string]$CountryName,
            [Parameter(Mandatory=$true)] [ValidateLength(1,127)] [string]$StateName,
            [Parameter(Mandatory=$false)] [ValidateRange(512,4096)] [int]$KeyFileBits=2048
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $fileName = $CommonName -replace "\*","wildcard"
    
        $certKeyFileName= "$($fileName).key"
        $certReqFileName = "$($fileName).req"
        $certFileName = "$($fileName).cert"
    
        $certReqFileFull = "$($env:TEMP)\$certReqFileName"
        $certFileFull = "$($env:TEMP)\$certFileName"
    
        try {
            Write-Verbose "Creating RSA key file"
            $payload = @{keyfile=$certKeyFileName;bits=$KeyFileBits}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslrsakey -Payload $payload -Action create

            Write-Verbose "Creating certificate request"
            $payload = @{reqfile=$certReqFileName;keyfile=$certKeyFileName;commonname=$CommonName;organizationname=$OrganizationName;countryname=$CountryName;statename=$StateName}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslcertreq -Payload $payload -Action create
    
            Write-Verbose "Downloading certificate request"
            $arguments = @{filelocation="/nsconfig/ssl"}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemfile -ResourceName $certReqFileName -Arguments $arguments
    
            if (-not [String]::IsNullOrEmpty($response.systemfile.filecontent)) {
                $certReqContentBase64 = $response.systemfile.filecontent
            } else {
                throw "Certificate request file content returned empty"
            }
            $certReqContent = [System.Convert]::FromBase64String($certReqContentBase64)
            $certReqContent | Set-Content $certReqFileFull -Encoding Byte
    
            Write-Verbose "Requesting certificate"
            certreq.exe -Submit -q -attrib "CertificateTemplate:webserver" -config $CAName $certReqFileFull $certFileFull
    
            if (-not $? -or $LASTEXITCODE -ne 0) {
                throw "certreq.exe failed to request certificate"
            }

            Write-Verbose "Uploading certificate"
            if (Test-Path $certFileFull) {
                $certContent = Get-Content $certFileFull -Encoding "Byte"
                $certContentBase64 = [System.Convert]::ToBase64String($certContent)

                $payload = @{filename=$certFileName;filecontent=$certContentBase64;filelocation="/nsconfig/ssl/";fileencoding="BASE64"}
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemfile -Payload $payload 
            } else {
                throw "Cert file '$certFileFull' not found."
            }

            Write-Verbose "Creating certificate request"
            Add-NSCertKeyPair -NSSession $NSSession -CertKeyName $fileName -CertPath $certFileName -KeyPath $certKeyFileName
        }
        finally {
            Write-Verbose "Cleaning up local temp files"
            Remove-Item -Path "$env:TEMP\$CommonName.*" -Force
        }

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
