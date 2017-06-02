    function New-NSSystemGroupSystemUserBinding {
        <#
        .SYNOPSIS
            Bind a system user to a given system group of the NetScaler Configuration
        .DESCRIPTION
            Bind a system user to a given system group of the NetScaler Configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to add the binding to. Minimum length = 1
        .PARAMETER UserName
            Name of the command policy that is binded to the group.
        .EXAMPLE
            Add-NSSystemGroupSystemUserBinding -NSSession $Session -GroupName group -UserName commandpolicy
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

        $payload = @{groupname=$GroupName; username=$UserName}

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemgroup_systemuser_binding -Payload $payload -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
