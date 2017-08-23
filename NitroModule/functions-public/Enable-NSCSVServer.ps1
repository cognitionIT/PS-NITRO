    function Enable-NSCSVServer {
        <#
        .SYNOPSIS
            Enable NetScaler Content Switching vServer
        .DESCRIPTION
            Enable NetScaler Content Switching vServer
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the Content Switching vServer to be enabled.
        .EXAMPLE
            Enable-NSCSVServer -NSSession $Session -Name cs_vsvr_unifiedgateway
        .NOTES
            Version:        1.0
            Author:         Esther Barthel, MSc
            Creation Date:  2017-08-21

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
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType csvserver -Payload $payload -ResourceName $Name -Action enable -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
