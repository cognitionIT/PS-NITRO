    function Get-NSTimeZone {
        <#
        .SYNOPSIS
            Retrieve Set NetScaler Appliance Timezone
        .DESCRIPTION
            Retrieve NetScaler Appliance Timezone
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
             Get-NSTimeZone -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )
    
        Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsconfig -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['nsconfig'])
        {
            return $response.nsconfig.timezone
        }
        else
        {
            return $null
        }
    }
