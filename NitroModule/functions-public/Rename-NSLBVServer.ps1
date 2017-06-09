    function Rename-NSLBVServer {
        <#
        .SYNOPSIS
            Rename the Load Balancing vServer name
        .DESCRIPTION
            Rename the Load Balancing vServer name
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the Load Balancing vServer
        .PARAMETER NewName
            New name for the Load Balancing vServer
        .EXAMPLE
            Rename-NSLBVServer -NSSession $session -Name "vsrv_lb-storefront" -NewName "vsvr_lb_storefront"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$NewName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name;newname=$NewName}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType lbvserver -Payload $payload -Action rename
        }

        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
