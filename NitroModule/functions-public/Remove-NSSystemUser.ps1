    function Remove-NSSystemUser {
        <#
        .SYNOPSIS
            Delete a system user resource from the NetScaler configuration
        .DESCRIPTION
            Delete a system user resource from the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name of the system user to delete. Minimum length = 1
        .EXAMPLE
            Delete-NSSystemUser -NSSession $Session -UserName user
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$UserName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType systemuser -ResourceName $UserName -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
