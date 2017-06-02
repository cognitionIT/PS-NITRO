    function Remove-NSSSLVServerCertKeyBinding {
    # Created: 20160912
        <#
        .SYNOPSIS
            Unbind a SSL certificate to a NetScaler vServer
        .DESCRIPTION
            Unbind a SSL certificate to a NetScaler vServer
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER vServerName
            Name of the NetScaler vServer to bind the certificate to
        .PARAMETER CertKeyName
            Name of the certificate-key pair to bind to the vServer
        .EXAMPLE
            Remove-NSSSLVServerCertKeyBinding -NSSession $Session -VServerName $name -CertKeyName "wildcard"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$VServerName,
            [Parameter(Mandatory=$false)] [string]$CertKeyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $args = @{}
        If (!([string]::IsNullOrEmpty($CertKeyName)))
        {
        $args.Add("certkeyname",$CertKeyName)
        }

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType sslvserver_sslcertkey_binding -ResourceName $VServerName -Arguments $args -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
