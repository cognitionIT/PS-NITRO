    function Remove-NSSystemGroup {
        <#
        .SYNOPSIS
            Delete a system group resource from the NetScaler configuration
        .DESCRIPTION
            Delete a system group resource from the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER GroupName
            Name of the group to delete. Minimum length = 1
        .EXAMPLE
            Delete-NSSystemGroup -NSSession $Session -GroupName group
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$GroupName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType systemgroup -ResourceName $GroupName

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
