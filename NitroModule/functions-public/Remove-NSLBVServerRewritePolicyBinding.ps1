    function Remove-NSLBVServerRewritePolicyBinding {
            <#
            .SYNOPSIS
                Remove a NetScaler Rewrite Policy binding to a vServer from the NetScalerConfiguration
            .DESCRIPTION
                Remove a NetScaler Rewrite Policy binding to a vServer from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the vServer.
            .PARAMETER PolicyName
                Name of the Rewrite policy
            .PARAMETER BindPoint
                Bind point to which to bind the policy. Applicable only to compression, rewrite, and cache policies. Possible values = REQUEST, RESPONSE
            .PARAMETER Priority
                Priority of the policy
            .EXAMPLE
                Remove-NSLBVServerRewritePolicyBinding -NSSession $NSSession -Name vsvr_lb_storefront -PolicyName rw_default_store
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            # vServer name
            [Parameter(Mandatory=$true)] [string]$Name,
            [Parameter(Mandatory=$true)] [string]$PolicyName,
            [Parameter(Mandatory=$false)][ValidateSet("REQUEST","RESPONSE")] [string]$BindPoint,
            [Parameter(Mandatory=$false)] [double]$Priority
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $args=@{policyname=$PolicyName}
            If ($Priority) {$payload.Add("priority",$Priority)}
            If (-not [string]::IsNullOrEmpty($BindPoint)){$payload.Add("bindpoint",$BindPoint)}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType lbvserver_rewritepolicy_binding -ResourceName $Name -Arguments $args -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
