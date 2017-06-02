    function Remove-NSSystemGroupSystemCmdPolicyBinding {
        <#
        .SYNOPSIS
            Unbind a system command policy to a given system group of the NetScaler Configuration
        .DESCRIPTION
            Unbind a system command policy to a given system group of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to add the binding to. Minimum length = 1
        .PARAMETER PolicyName
            Name of the command policy that is binded to the group.
        .EXAMPLE
            Remove-NSSystemGroupSystemCmdPolicyBinding -NSSession $Session -GroupName group -PolicyName commandpolicy
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName,
            [Parameter(Mandatory=$true)] [string]$PolicyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $args = @{policyname=$PolicyName}

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType systemgroup_systemcmdpolicy_binding -ResourceName $GroupName -Arguments $args

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
