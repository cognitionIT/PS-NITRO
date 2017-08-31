    function Rename-NSCSPolicy {
        <#
        .SYNOPSIS
            Rename the Content Switching policy name
        .DESCRIPTION
            Rename the Content Switching policy name
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the CS Policy
        .PARAMETER NewName
            New name for the CS Policy
        .EXAMPLE
            Rename-NSCSPolicy -NSSession $session -Name "cs_policy_unifiedgateway" -NewName "cs_pol_unifiedgateway"
        .NOTES
            Version:        1.0
            Author:         Esther Barthel, MSc
            Creation Date:  2017-08-30

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
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType cspolicy -Payload $payload -Action rename
        }

        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
