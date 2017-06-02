    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    function Get-NSMgmtProtocol {
        <#
        .SYNOPSIS
            Get the value of $Script:NSURLProtocol
        .DESCRIPTION
            Set $Script:NSURLProtocol
        .EXAMPLE
            $protocol  = Get-Protocol
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param()

        return $Script:NSURLProtocol 
    }
