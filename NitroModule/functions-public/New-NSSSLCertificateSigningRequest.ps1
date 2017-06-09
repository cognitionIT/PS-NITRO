    # Created: 20160829
    function New-NSSSLCertificateSigningRequest {
        <#
        .SYNOPSIS
            Create a Certificate Signing Request (CSR)
        .DESCRIPTION
            Create a Certificate Signing Request (CSR)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER RequestFileName
            Name for and, optionally, path to the certificate signing request (CSR). /nsconfig/ssl/ is the default path. Maximum length = 63
        .PARAMETER KeyFile
            Name of and, optionally, path to the private key used to create the certificate signing request, which then becomes part of the certificate-key pair. The private key can be either an RSA or a DSA key. The key must be present in the appliance's local storage. /nsconfig/ssl is the default path.
        .PARAMETER FipsKeyName
            Name of the FIPS key used to create the certificate signing request. FIPS keys are created inside the Hardware Security Module of the FIPS card.
            Minimum length = 1. Maximum length = 31
        .PARAMETER KeyFormat
            Format in which the key is stored on the appliance. Default value: PEM. Possible values = DER, PEM.
        .PARAMETER PEMPassphrase
            Password for the PEM certificate file
        .PARAMETER CountryName
            Two letter ISO code for your country. For example, US for United States.
        .PARAMETER StateName
            Full name of the state or province where your organization is located. 
        .PARAMETER OrganizationName
            Name of the organization that will use this certificate. The organization name (corporation, limited partnership, university, or government agency) must be registered with some authority at the national, state, or city level. Use the legal name under which the organization is registered. 
        .PARAMETER OrganizationUnitName
            Name of the division or section in the organization that will use the certificate.
        .PARAMETER LocalityName
            Name of the city or town in which your organization's head office is located.
        .PARAMETER CommonName
            Fully qualified domain name for the company or web site. The common name must match the name used by DNS servers to do a DNS lookup of your server.
        .PARAMETER EmailAddress
            Contact person's e-mail address. This address is publically displayed as part of the certificate.
        .PARAMETER ChallengePassword
            Pass phrase, embedded in the certificate signing request that is shared only between the client or server requesting the certificate and the SSL certificate issuer (typically the certificate authority).
        .PARAMETER CompanyName
            Additional name for the company or web site.
        .PARAMETER DigestMethod
            Digest algorithm used in creating CSR. Possible values = SHA1, SHA256
        .EXAMPLE
            New-NSSSLCertificateSigningRequest -NSSession $Session -RequestFileName selfsigned.csr -KeyFile selfsigned.key -KeyFormat PEM -PEMPassPhrase "password" -CountryName NL StateName Friesland -OrganizationName cognitionIT -DigestMethod SHA256
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$RequestFileName,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$KeyFile,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$FipsKeyName,
            [Parameter(Mandatory=$false)] [ValidateSet("PEM","DER")] [string]$KeyFormat,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$PEMPassphrase,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$CountryName,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$StateName,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$OrganizationName,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$OrganizationUnitName,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$LocalityName,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$CommonName,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$EmailAddress,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$ChallengePassword,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$CompanyName,
            [Parameter(Mandatory=$false)] [ValidateSet("SHA1","SHA256")] [string]$DigestMethod
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{reqfile=$RequestFileName;countryname=$CountryName;statename=$StateName;organizationname=$OrganizationName}

            if ($KeyFile) {
                $payload.Add("keyfile",$KeyFile)
            }
            if ($FipsKeyName) {
                $payload.Add("fipskeyname",$FipsKeyName)
            }
            if ($KeyFormat) {
                $payload.Add("keyform",$KeyFormat)
            }
            if ($OrganizationUnitName) {
                $payload.Add("organizationunitname",$OrganizationUnitName)
            }
            If ($DigestMethod)
            {
                $payload.Add("digestmethod",$DigestMethod)
            }
            If ($PEMPassphrase)
            {
                $payload.Add("pempassphrase",$PEMPassphrase)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslcertreq -Payload $payload -Action create -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
