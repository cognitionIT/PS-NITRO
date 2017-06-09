    function Get-NSLBVServerRewritePolicyBinding {
        <#
        .SYNOPSIS
            Retrieve NetScaler vServer Rewrite Policy Binding
        .DESCRIPTION
            Retrieve NetScaler vServer Rewrite Policy Binding
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the Load Balancing vServer.
        .EXAMPLE
            Get-NSLBVServerRewritePolicyBinding -NSSession $Session -Name vsvr_lb_storefront
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
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType lbvserver_rewritepolicy_binding -ResourceName $Name -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['lbvserver_rewritepolicy_binding'])
            {
                return $response.lbvserver_rewritepolicy_binding
            }
            else
            {
                return $null
            }
        }
    }
