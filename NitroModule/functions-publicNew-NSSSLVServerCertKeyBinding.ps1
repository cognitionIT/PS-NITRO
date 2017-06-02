    # New-NSSSLVServerCertKeyBinding is part of the Citrix NITRO Module
    function New-NSSSLVServerCertKeyBinding {
        <#
        .SYNOPSIS
            Bind a SSL certificate-key pair to a virtual server
        .DESCRIPTION
            Bind a SSL certificate-key pair to a virtual server
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertKeyName
            Name of the certificate key pair
        .PARAMETER VirtualServerName
            Name of the virtual server
        .EXAMPLE
            New-NSVPNVServerSSLCertKeyBinding -NSSession $Session -CertKeyName "*.xd.local" -VServerName myvs -WebSession $Session
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$CertKeyName,
            [Parameter(Mandatory=$true)] [string]$VirtualServerName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload =  @{certkeyname=$CertKeyName;vservername=$VirtualServerName}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType sslvserver_sslcertkey_binding -Payload $payload  

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
