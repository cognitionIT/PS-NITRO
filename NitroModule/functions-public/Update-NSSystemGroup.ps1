    function Update-NSSystemGroup {
        <#
        .SYNOPSIS
            Update a system group resource of the NetScaler configuration
        .DESCRIPTION
            Update a system group resource of the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to update. Minimum length = 1
        .PARAMETER PromptString
            String to display at the command-line prompt. Minimum length = 1
        .PARAMETER Timeout
            CLI session inactivity timeout, in seconds. Default value is 900 seconds.
        .EXAMPLE
            Update-NSSystemGroup -NSSession $Session -GroupName group -PromptString grpstring -Timeout 300
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName,
            [Parameter(Mandatory=$false)] [string]$PromptString,
            [Parameter(Mandatory=$false)] [ValidateRange(0,100000000)][int]$Timeout=900
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{groupname=$GroupName}

        if ($Timeout) {
            $payload.Add("timeout",$Timeout)
        }

        if (-not [string]::IsNullOrEmpty($PromptString)) {
            $payload.Add("promptstring",$PromptString)
        }

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType systemgroup -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
