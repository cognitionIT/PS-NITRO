    function Rename-NSCSVServer {
        <#
        .SYNOPSIS
            Rename the Content Switching vServer name
        .DESCRIPTION
            Rename the Content Switching vServer name
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the CS vServer
        .PARAMETER NewName
            New name for the CS vServer
        .EXAMPLE
            Rename-NSCSVServer -NSSession $session -Name "vsrv_cs_unifiedgateway" -NewName "cs_vsvr_unifiedgateway"
        .NOTES
            Version:        1.0
            Author:         Esther Barthel, MSc
            Creation Date:  2017-08-21

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
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType csvserver -Payload $payload -Action rename
        }

        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
