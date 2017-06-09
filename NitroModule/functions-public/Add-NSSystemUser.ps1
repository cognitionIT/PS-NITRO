    function Add-NSSystemUser {
        <#
        .SYNOPSIS
            Add a system user resource to the NetScaler configuration
        .DESCRIPTION
            Add a system user resource to the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name for a user. Cannot be changed after the user is added. Minimum length = 1
        .PARAMETER Password
            Password for the system user. Can include any ASCII character. Minimum length = 1
        .PARAMETER ExternalAuth
            Switch parameter.
            Whether to use external authentication servers for the system user authentication or not. Default value: ENABLED. Possible values = ENABLED, DISABLED.
        .PARAMETER PromptString
            String to display at the command-line prompt. Minimum length = 1
        .PARAMETER Timeout
            CLI session inactivity timeout, in seconds. Default value is 900 seconds.
        .PARAMETER Logging
            Switch parameter.
            Users logging privilege. Default value: DISABLED. Possible values = ENABLED, DISABLED.
        .EXAMPLE
            Add-NSSystemUser -NSSession $Session -UserName user -Password password
        .EXAMPLE
            Add-NSSystemUser -NSSession $Session -UserName user -Password password -ExternalAuth -Timeout 300 -Logging
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$UserName,
            [Parameter(Mandatory=$true)] [string]$Password,
            [Parameter(Mandatory=$false)] [switch]$ExternalAuth,
            [Parameter(Mandatory=$false)] [string]$PromptString,
            [Parameter(Mandatory=$false)] [ValidateRange(0,100000000)][int]$Timeout=900,
            [Parameter(Mandatory=$false)] [switch]$Logging=$false
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $extauth = if ($ExternalAuth) { "ENABLED" } else { "DISABLED" }
        $userlogging = if ($Logging) { "ENABLED" } else { "DISABLED" }

        $payload = @{username=$UserName;password=$Password;externalauth=$extauth;logging=$userlogging}

        if ($Timeout) {
            $payload.Add("timeout",$Timeout)
        }

        if (-not [string]::IsNullOrEmpty($PromptString)) {
            $payload.Add("promptstring",$PromptString)
        }

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemuser -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
