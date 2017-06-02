    function Remove-NSSystemUserSystemCmdPolicyBinding {
        <#
        .SYNOPSIS
            Unbind a system command policy from a given system user of the NetScaler Configuration
        .DESCRIPTION
            Unbind a system command policy from a given system user of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name of the user to remove the binding from. Minimum length = 1
        .PARAMETER PolicyName
            Name of the command policy that is unbinded from the group.
        .EXAMPLE
            Remove-NSSystemUserSystemCmdPolicyBinding -NSSession $Session -UserName user -PolicyName commandpolicy
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$UserName,
            [Parameter(Mandatory=$true)] [string]$PolicyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $args = @{policyname=$PolicyName}

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType systemuser_systemcmdpolicy_binding -ResourceName $UserName -Arguments $args -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
