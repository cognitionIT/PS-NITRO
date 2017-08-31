    function Rename-NSCSAction {
        <#
        .SYNOPSIS
            Rename the Content Switching Action name
        .DESCRIPTION
            Rename the Content Switching Action name
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the CS Action
        .PARAMETER NewName
            New name for the CS Action
        .EXAMPLE
            Rename-NSCSAction -NSSession $session -Name "cs_action_unifiedgateway" -NewName "cs_act_unifiedgateway"
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
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType csaction -Payload $payload -Action rename
        }

        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
