    function Enable-NSLBVServer {
        <#
        .SYNOPSIS
            Enable NetScaler Load Balacing vServer
        .DESCRIPTION
            Enable NetScaler Load Balacing vServer
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the Load Balancing vServer to be enabled.
        .EXAMPLE
            Enable-NSLBVServer -NSSession $Session -Name vsvr_lb_storefront
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$Name
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType lbvserver -Payload $payload -ResourceName $Name -Action enable -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
