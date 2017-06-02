    # Add-NSCertKeyPair is part of the Citrix NITRO Module
    function Add-NSCertKeyPair {
        <#
        .SYNOPSIS
            Add SSL certificate and private key pair
        .DESCRIPTION
            Add SSL certificate and private key  pair
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertKeyName
            Name for the certificate and private-key pair
        .PARAMETER CertPath
            Path to the X509 certificate file that is used to form the certificate-key pair
        .PARAMETER KeyPath
            path to the private-key file that is used to form the certificate-key pair
        .PARAMETER CertKeyFormat
            Input format of the certificate and the private-key files, allowed values are "PEM" and "DER", default to "PEM"
        .PARAMETER Passcrypt
            Pass phrase used to encrypt the private-key. Required when adding an encrypted private-key in PEM format
        .EXAMPLE
            Add-NSCertKeyPair -NSSession $Session -CertKeyName "*.xd.local" -CertPath "/nsconfig/ssl/ns.cert" -KeyPath "/nsconfig/ssl/ns.key" -CertKeyFormat PEM -Passcrypt "luVJAUxtmUY="
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$CertKeyName,
            [Parameter(Mandatory=$true)] [string]$CertPath,
            [Parameter(Mandatory=$true)] [string]$KeyPath,
            [Parameter(Mandatory=$false)] [ValidateSet("PEM","DER")] [string]$CertKeyFormat="PEM",
            [Parameter(Mandatory=$false)] [string]$Passcrypt
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload = @{certkey=$CertKeyName;cert=$CertPath;key=$KeyPath;inform=$CertKeyFormat}
        if ($CertKeyFormat -eq "PEM" -and $Passcrypt) {
            $payload.Add("passcrypt",$Passcrypt)
        }
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslcertkey -Payload $payload  

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
