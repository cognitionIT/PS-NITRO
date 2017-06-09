        function Enable-NSServer {
        <#
        .SYNOPSIS
            Enable NetScaler Server
        .DESCRIPTION
            Enable NetScaler Server
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the Server to be enabled.
        .EXAMPLE
            Enable-NSServer -NSSession $Session -Name storefront.demo.lab
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
                $payload = @{name=$Name}
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType server -Payload $payload -Verbose:$VerbosePreference -Action enable
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
