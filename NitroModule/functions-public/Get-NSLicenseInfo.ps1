    function Get-NSLicenseInfo {
        <#
        .SYNOPSIS
            Retrieve the NetScaler License information
        .DESCRIPTION
            Retrieve the NetScaler License information
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Get-NSLicenseInfo -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nslicense -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        return $response.nslicense
    }
