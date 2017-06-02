    function Update-NSSystemUser {
        <#
        .SYNOPSIS
            Update a system user resource of the NetScaler configuration
        .DESCRIPTION
            Update a system user resource of the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name of the system user to update. Minimum length = 1
        .PARAMETER Password
            Password for the system user. Can include any ASCII character. Minimum length = 1
        .SWITCH ExternalAuth
            Whether to use external authentication servers for the system user authentication or not. Default value: ENABLED. Possible values = ENABLED, DISABLED.
        .PARAMETER PromptString
            String to display at the command-line prompt. Minimum length = 1
        .PARAMETER Timeout
            CLI session inactivity timeout, in seconds. Default value is 900 seconds.
        .SWITCH Logging
            Users logging privilege. Default value: DISABLED. Possible values = ENABLED, DISABLED.
        .EXAMPLE
            Update-NSSystemUser -NSSession $Session -UserName user -Password password
        .EXAMPLE
            Update-NSSystemUser -NSSession $Session -UserName user -Password password -ExternalAuth -Timeout 300 -Logging
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$UserName,
            [Parameter(Mandatory=$false)] [string]$Password,
            [Parameter(Mandatory=$false)] [switch]$ExternalAuth=$false,
            [Parameter(Mandatory=$false)] [string]$PromptString,
            [Parameter(Mandatory=$false)] [ValidateRange(0,100000000)][int]$Timeout=900,
            [Parameter(Mandatory=$false)] [switch]$Logging=$false
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $extauth = if ($ExternalAuth) { "ENABLED" } else { "DISABLED" }
        $userlogging = if ($Logging) { "ENABLED" } else { "DISABLED" }

        $payload = @{username=$UserName;externalauth=$extauth;logging=$userlogging}

        if ($Timeout) {
            $payload.Add("timeout",$Timeout)
        }

        if (-not [string]::IsNullOrEmpty($Password)) {
            $payload.Add("password",$Password)
        }
        if (-not [string]::IsNullOrEmpty($PromptString)) {
            $payload.Add("promptstring",$PromptString)
        }

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType systemuser -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
