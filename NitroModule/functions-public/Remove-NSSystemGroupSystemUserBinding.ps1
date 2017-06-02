    function Remove-NSSystemGroupSystemUserBinding {
        <#
        .SYNOPSIS
            Unbind a system user from a given system group of the NetScaler Configuration
        .DESCRIPTION
            Unbind a system user from a given system group of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to add the binding to. Minimum length = 1
        .PARAMETER PolicyName
            Name of the system user that is binded to the group.
        .EXAMPLE
            Remove-NSSystemGroupSystemUserBinding -NSSession $Session -GroupName group -UserName systemuser
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName,
            [Parameter(Mandatory=$true)] [string]$UserName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $args = @{username=$UserName}

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType systemgroup_systemuser_binding -ResourceName $GroupName -Arguments $args

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
