    # NOTE: Shutdown cannot be performed from the configuration utility
    # { "errorcode": 340, "message": "Not super-user", "severity": "ERROR" }
    function Stop-NSAppliance {
    <#
        .SYNOPSIS
            Shutdown NetScaler Appliance
        .DESCRIPTION
            Shutdown NetScaler Appliance
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Shutdown-NSAppliance -NSSession $Session 
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{}
        #$payload.Add("shutdown","")

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType shutdown -Payload $payload -Action shutdown -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
