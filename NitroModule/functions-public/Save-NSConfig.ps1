    # Save-NSConfig is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    function Save-NSConfig {
        <#
        .SYNOPSIS
            Save NetScaler Config File 
        .DESCRIPTION
            Save NetScaler Config File 
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .EXAMPLE
            Save-NSConfig -NSSession $Session
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 
    
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsconfig -Action "save"

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
