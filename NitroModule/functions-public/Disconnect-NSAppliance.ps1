    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    function Disconnect-NSAppliance {
        <#
        .SYNOPSIS
            Disconnect NetScaler Appliance session
        .DESCRIPTION
            Disconnect NetScaler Appliance session
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Disconnect-NSAppliance -NSSession $Session
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $logout = @{"logout" = @{}}
        $logoutJson = ConvertTo-Json $logout
    
        try {
            Write-Verbose "Calling Invoke-RestMethod for logout"
            $response = Invoke-RestMethod -Uri "$($Script:NSURLProtocol)://$($NSSession.Endpoint)/nitro/v1/config/logout" -Body $logoutJson -Method POST -ContentType application/json -WebSession $NSSession.WebSession
        }
        catch [Exception] {
            throw $_
        }

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
