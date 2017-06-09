        function Enable-NSServiceGroup {
        <#
        .SYNOPSIS
            Enable NetScaler ServiceGroup
        .DESCRIPTION
            Enable NetScaler ServiceGroup
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the ServiceGroup to be enabled.
        .EXAMPLE
            Enable-NSServiceGroup -NSSession $Session -Name svcgrp_storefront
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
                $payload = @{servicegroupname=$Name}
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType servicegroup -Payload $payload -Verbose:$VerbosePreference -Action enable
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
