    # Created: 20160912
    function Add-NSSSLVServerCertKeyBinding {
        <#
        .SYNOPSIS
            Bind a SSL certificate to a NetScaler vServer
        .DESCRIPTION
            Bind a SSL certificate to a NetScaler vServer
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER vServerName
            Name of the NetScaler vServer to bind the certificate to
        .PARAMETER CertKeyName
            Name of the certificate-key pair to bind to the vServer
        .PARAMETER CRLCheck
            The state of the CRL check parameter. (Mandatory/Optional). Possible values = Mandatory, Optional
        .PARAMETER OCSPCheck
            The state of the OCSP check parameter. (Mandatory/Optional). Possible values = Mandatory, Optional
        .PARAMETER CA
            Switch parameter.
            CA certificate.
        .PARAMETER SkipCAName
            Switch parameter.
            The flag is used to indicate whether this particular CA certificate's CA_Name needs to be sent to the SSL client while requesting for client certificate in a SSL handshake.
        .PARAMETER SNICert
            Switch parameter.
            The name of the CertKey. Use this option to bind Certkey(s) which will be used in SNI processing.
        .EXAMPLE
            Add-NSSSLVServerCertKeyBinding -NSSession $Session -VServerName $name -CertKeyName "wildcard"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$VServerName,
            [Parameter(Mandatory=$true)] [string]$CertKeyName,
            [Parameter(Mandatory=$false)] [ValidateSet("Mandatory","Optional")] [string]$CRLCheck,
            [Parameter(Mandatory=$false)] [ValidateSet("Mandatory","Optional")] [string]$OCSPCheck,
            [Parameter(Mandatory=$false)] [switch]$CA,
            [Parameter(Mandatory=$false)] [switch]$SkipCAName,
            [Parameter(Mandatory=$false)] [switch]$SNICert
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"
        $CAValue = if ($CA) { "true" } else { "false" }
        $SkipCANameValue = if ($SkipCAName) { "true" } else { "false" }
        $SNICertValue = if ($SNICert) { "true" } else { "false" }

        $payload = @{vservername=$VServerName;certkeyname=$CertKeyName;ca=$CAValue;skipcaname=$SkipCANameValue;snicert=$SNICertValue}

        If (!([string]::IsNullOrEmpty($CRLCheck)))
        {
            $payload.Add("crlcheck",$CRLCheck)
        }
        If (!([string]::IsNullOrEmpty($OCSPCheck)))
        {
            $payload.Add("ocspcheck",$OCSPCheck)
        }

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType sslvserver_sslcertkey_binding -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
