    function New-NSSystemUserSystemCmdPolicyBinding {
        <#
        .SYNOPSIS
            Bind a system command policy to a given system user of the NetScaler Configuration
        .DESCRIPTION
            Bind a system command policy to a given system user of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name of the user to add the binding to. Minimum length = 1
        .PARAMETER PolicyName
            Name of the command policy that is binded to the group.
        .PARAMETER Priority
            The priority of the command policy
        .EXAMPLE
            Add-NSSystemUserSystemCmdPolicyBinding -NSSession $Session -UserName group -PolicyName commandpolicy
        .EXAMPLE
            Add-NSSystemUserSystemCmdPolicyBinding -NSSession $Session -UserName group -PolicyName commandpolicy -Priority 90
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$UserName,
            [Parameter(Mandatory=$true)] [string]$PolicyName,
            [Parameter(Mandatory=$false)] [int]$Priority
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $prio = if ($Priority) { $Priority } else { 100 }

        $payload = @{username=$UserName; policyname=$PolicyName; priority=$prio}

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemuser_systemcmdpolicy_binding -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
