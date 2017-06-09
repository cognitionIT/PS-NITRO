    function Get-NSLBVServerResponderPolicyBinding {
        <#
        .SYNOPSIS
            Retrieve NetScaler vServer Responder Policy Binding
        .DESCRIPTION
            Retrieve NetScaler vServer Responder Policy Binding
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the Load Balancing vServer.
        .EXAMPLE
            Get-NSLBVServerResponderPolicyBinding -NSSession $Session -Name vsvr_lb_storefront
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
        }
        Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType lbvserver_responderpolicy_binding -ResourceName $Name -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['lbvserver_responderpolicy_binding'])
            {
                return $response.lbvserver_responderpolicy_binding
            }
            else
            {
                return $null
            }
        }
    }
