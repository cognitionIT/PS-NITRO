    function Set-NSCSParameter {
        <#
        .SYNOPSIS
            Update the Global CS Parameters 
        .DESCRIPTION
            Update existing CS Parameters
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER StateUpdate
            Specifies whether the virtual server checks the attached load balancing server for state information.
            Default value: DISABLED
            Possible values = ENABLED, DISABLED.
        .EXAMPLE
            Set-NSCSParameter -NSSession $Session -StateUpdate ENABLED
        .NOTES
            Version:        1.0
            Author:         Esther Barthel, MSc
            Creation Date:  2017-08-30

            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$StateUpdate="DISABLED"
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{stateupdate=$StateUpdate}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType csparameter -Payload $payload 
        }

        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
