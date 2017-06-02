    function New-NSSystemGroupSystemCmdPolicyBinding {
        <#
        .SYNOPSIS
            Bind a system command policy to a given system group of the NetScaler Configuration
        .DESCRIPTION
            Bind a system command policy to a given system group of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to add the binding to. Minimum length = 1
        .PARAMETER PolicyName
            Name of the command policy that is binded to the group.
        .PARAMETER Priority
            The priority of the command policy
        .EXAMPLE
            Add-NSSystemGroupSystemCmdPolicyBinding -NSSession $Session -GroupName group -PolicyName commandpolicy
        .EXAMPLE
            Add-NSSystemGroupSystemCmdPolicyBinding -NSSession $Session -GroupName group -PolicyName commandpolicy -Priority 90
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName,
            [Parameter(Mandatory=$true)] [string]$PolicyName,
            [Parameter(Mandatory=$false)] [int]$Priority
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $prio = if ($Priority) { $Priority } else { 100 }

        $payload = @{groupname=$GroupName; policyname=$PolicyName; priority=$prio}

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemgroup_systemcmdpolicy_binding -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
