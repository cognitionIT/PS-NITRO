    function Add-NSSSLCertKeyLink {
    # Created: 20160829
        <#
        .SYNOPSIS
            Link a SSL certificate to another SSL certificate
        .DESCRIPTION
            Link a SSL certificate to another SSL certificate
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertKeyName
            Name for the certificate and private-key pair
        .PARAMETER LinkCertKeyName
            Name for the Linked certificate and private-key pair
        .EXAMPLE
            Add-NSCertKeyPair -NSSession $Session -CertKeyName "wildcard" -LinkCertKeyName "rootCA"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$CertKeyName,
            [Parameter(Mandatory=$true)] [string]$LinkCertKeyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload = @{certkey=$CertKeyName;linkcertkeyname=$LinkCertKeyName}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslcertkey -Payload $payload -Action link -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
