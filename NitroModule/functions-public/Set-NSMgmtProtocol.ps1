    # Define default URL protocol to https, which can be changed by calling Set-Protocol function
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    $Script:NSURLProtocol = "https"

    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    function Set-NSMgmtProtocol {
        <#
        .SYNOPSIS
            Set $Script:NSURLProtocol, this will be used for all subsequent invocation of NITRO APIs
        .DESCRIPTION
            Set $Script:NSURLProtocol
        .PARAMETER Protocol
            Protocol, acceptable values are "http" and "https"
        .EXAMPLE
            Set-NSMgmtProtocol -Protocol https
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [ValidateSet("http","https")] [string]$Protocol
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $Script:NSURLProtocol = $Protocol

        Write-Verbose "NSURLProtocol set to $Script:NSURLProtocol"
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
