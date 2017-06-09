        function Enable-NSService {
        <#
        .SYNOPSIS
            Enable NetScaler Service
        .DESCRIPTION
            Enable NetScaler Service
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the Service to be enabled.
        .EXAMPLE
            Enable-NSService -NSSession $Session -Name svc_storefront
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
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType service -Payload $payload -Verbose:$VerbosePreference -Action enable
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
