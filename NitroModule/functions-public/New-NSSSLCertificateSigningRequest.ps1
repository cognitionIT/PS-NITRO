    function New-NSSSLCertificateSigningRequest {
    # Created: 20160829
        <#
        .SYNOPSIS
            Create a Certificate Signing Request (CSR)
        .DESCRIPTION
            Create a Certificate Signing Request (CSR)
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
