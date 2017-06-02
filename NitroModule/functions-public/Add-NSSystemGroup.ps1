    function Add-NSSystemGroup {
        <#
        .SYNOPSIS
            Add a system group resource to the NetScaler configuration
        .DESCRIPTION
            Add a system group resource to the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name for the group. Cannot be changed after the group is added. Minimum length = 1
        .PARAMETER PromptString
            String to display at the command-line prompt. Minimum length = 1
        .PARAMETER Timeout
            CLI session inactivity timeout, in seconds. Default value is 900 seconds.
        .EXAMPLE
            Add-NSSystemGroup -NSSession $Session -GroupName group
        .EXAMPLE
            Add-NSSystemGroup -NSSession $Session -GroupName group -PromptString grpstring -Timeout 300
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

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemgroup -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
