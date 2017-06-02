    function Add-NSSSLCertKey {
    # Created: 20160829
        <#
        .SYNOPSIS
            Install a SSL certificate key pair
        .DESCRIPTION
            Install a SSL certificate key pair
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertKeyName
            Name for the certificate and private-key pair
        .PARAMETER CertPath
            Path to the X509 certificate file that is used to form the certificate-key pair
        .PARAMETER KeyPath
            path to the optional private-key file that is used to form the certificate-key pair
        .PARAMETER CertKeyFormat
            Input format of the certificate and the private-key files, allowed values are "PEM" and "DER", default to "PEM"
        .PARAMETER Password
            Pass phrase used to encrypt the private-key. Required when adding an encrypted private-key in PEM format
        .SWITCH ExpiryMonitor
            Determines whether the expiration of a certificate needs to be monitored
        .PARAMETER NotificationPeriod
            How many days before the certificate is expiring a notification is shown
        .EXAMPLE
            Add-NSCertKeyPair -NSSession $Session -CertKeyName "*.xd.local" -CertPath "/nsconfig/ssl/ns.cert" -KeyPath "/nsconfig/ssl/ns.key" -CertKeyFormat PEM -Password "luVJAUxtmUY=" -ExpiryMonitor -NotificationPeriod 25
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$CertKeyName,
            [Parameter(Mandatory=$true)] [string]$CertPath,
            [Parameter(Mandatory=$false)] [string]$KeyPath,
            [Parameter(Mandatory=$true)] [ValidateSet("PEM","DER","PFX")] [string]$CertKeyFormat="PEM",
            [Parameter(Mandatory=$false)] [string]$Password,
            [Parameter(Mandatory=$false)] [switch]$ExpiryMonitor,
            [Parameter(Mandatory=$false)] [ValidateRange(10,100)][int]$NotificationPeriod=30
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $ExpiryMonitorValue = if ($ExpiryMonitor) { "ENABLED" } else { "DISABLED" }

        $payload = @{certkey=$CertKeyName;cert=$CertPath;inform=$CertKeyFormat;expirymonitor=$ExpiryMonitorValue}
        if ($NotificationPeriod) {
            $payload.Add("notificationperiod",$NotificationPeriod)
        }
        If (!([string]::IsNullOrEmpty($KeyPath)))
        {
            $payload.Add("key",$KeyPath)
        }
        if ($CertKeyFormat -eq "PEM" -and $Password) {
            $payload.Add("passplain",$Password)
        }
        if ($CertKeyFormat -eq "PFX" -and $Password) {
            $payload.Add("passplain",$Password)
        }
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType sslcertkey -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
