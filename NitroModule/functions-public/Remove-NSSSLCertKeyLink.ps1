    # Created: 20160829
    function Remove-NSSSLCertKeyLink {
        <#
        .SYNOPSIS
            Remove the cert link for a SSL certificate
        .DESCRIPTION
            Remove the cert link for a SSL certificate
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertKeyName
            Name for the certificate and private-key pair
        .EXAMPLE
            Remove-NSSSLCertKeyLink -NSSession $Session -CertKeyName "wildcard.demo.lab"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$CertKeyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload = @{certkey=$CertKeyName}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslcertkey -Payload $payload -Action unlink -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
