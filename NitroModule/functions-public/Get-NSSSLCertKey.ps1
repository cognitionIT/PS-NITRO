    # Created: 20160905
    function Get-NSSSLCertKey {
        <#
        .SYNOPSIS
            Retrieve certificate key resource(s) from the NetScaler configuration
        .DESCRIPTION
            Retrieve certificate key resource(s) from the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertName
            Name of the certificate key resource to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSSLCertKey -NSSession $Session -CertName $certname
        .EXAMPLE
            Get-NSSSLCertKey -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$CertName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        If (-not [string]::IsNullOrEmpty($CertName)) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType sslcertkey -ResourceName $CertName -Verbose:$VerbosePreference
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType sslcertkey -Verbose:$VerbosePreference
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['sslcertkey'])
        {
            return $response.sslcertkey
        }
        else
        {
            return $null
        }
    }
