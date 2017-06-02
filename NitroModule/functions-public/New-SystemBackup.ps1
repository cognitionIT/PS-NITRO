    function New-SystemBackup {
        <#
        .SYNOPSIS
            Backup NetScaler Appliance
        .DESCRIPTION
            Restart NetScaler Appliance, with an option to save NetScaler Config File before rebooting
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER SaveNSConfig
            Switch Parameter to save NetScaler Config file before rebooting.
        .PARAMETER WarmReboot
            Switch Parameter to perform warm reboot of the NetScaler appliance
        .PARAMETER Wait
            Switch Parameter to wait after reboot until Nitro REST API is online
        .PARAMETER WaitTimeout
            Timeout in seconds for the wait after reboot
        .EXAMPLE
            Save NetScaler Config file and restart NetScaler VPX
            Restart-NSAppliance -NSIP 10.108.151.1 -SaveNSConfig -WebSession $session
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Filename,
            [Parameter(Mandatory=$true)][ValidateSet("Full","Basic")] [string]$Level="Basic",
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Comment
        )
        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload=@{level=$Level}
        if ($Filename) {$payload.Add("filename",$Filename)}
    
        If (!([string]::IsNullOrEmpty($Comment))) {$payload.Add("comment",$Comment)}

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systembackup -Payload $payload -Action create


        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
