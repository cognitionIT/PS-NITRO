    function Get-NSHostName {
        <#
        .SYNOPSIS
            Get NetScaler Appliance Hostname
        .DESCRIPTION
            Get NetScaler Appliance Hostname
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
             Get-NSHostName -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nshostname -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['nshostname'])
        {
            return $response.nshostname.hostname
        }
        else
        {
            return $null
        }
    }
