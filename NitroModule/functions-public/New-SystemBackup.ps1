    function New-SystemBackup {
        <#
        .SYNOPSIS
            Backup NetScaler Appliance
        .DESCRIPTION
            Backup NetScaler Appliance
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Filename
            Name of the backup file(*.tgz) to be created.
        .PARAMETER Level
            Level of data to be backed up. Default value: basic. Possible values = basic, full
        .PARAMETER Comment
            Comment specified at the time of creation of the backup file(*.tgz).
        .EXAMPLE
            Save NetScaler Config file and restart NetScaler VPX
            New-SystemBackup -NSSession $NSSession -Filename nsbackup.tgz -Level Full -Comment "weekly backup"
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
