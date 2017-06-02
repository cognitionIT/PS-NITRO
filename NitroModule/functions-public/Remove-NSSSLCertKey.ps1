    function Remove-NSSSLCertKey {
    # Created: 20160906
        <#
        .SYNOPSIS
            Remove a SSL Cert Key pair
        .DESCRIPTION
            Remove a SSL Cert Key pair
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertKeyName
            Name for the certificate and private-key pair
        .EXAMPLE
            Remove-NSSSLCertKey -NSSession $Session -CertKeyName "*.xd.local"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$CertKeyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType sslcertkey -ResourceName $CertKeyName -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
