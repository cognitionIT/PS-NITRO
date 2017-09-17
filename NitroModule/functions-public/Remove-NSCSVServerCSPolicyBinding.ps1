    function Remove-NSCSVServerCSPolicyBinding {
            <#
            .SYNOPSIS
                Remove a NetScaler CS Policy binding from the NetScalerConfiguration
            .DESCRIPTION
                Remove a NetScaler Content Switching Policy binding from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the content switching virtual server to which the content switching policy applies.
                Minimum length = 1
            .PARAMETER PolicyName
                Policy bound to this vserver.
            .PARAMETER Priority
                Priority for the policy.
            .PARAMETER Bindpoint
                The bindpoint to which the policy is bound. 
                Possible values = REQUEST, RESPONSE
            .EXAMPLE
                Remove-NSCVServerCSPolicyBinding -NSSession $Session -Name "cs_vsvr_one_url_test" -PolicyName "cs_pol_gateway" -Priority =100
            .NOTES
                Version:        1.0
                Author:         Esther Barthel, MSc
                Creation Date:  2017-08-30

                Copyright (c) cognition IT. All rights reserved.
            #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$Name,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$PolicyName,
            [Parameter(Mandatory=$false)] [int]$Priority,
            [Parameter(Mandatory=$false)] [ValidateSet("REQUEST","RESPONSE")] [string]$Bindpoint
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $args=@{name=$Name}
        }
        Process {
            if (-not [string]::IsNullOrEmpty($PolicyName)) {$args.Add("policyname",$PolicyName)}
            if ($Priority) {$payload.Add("priority",$Priority)}
            if (-not [string]::IsNullOrEmpty($Bindpoint)) {$args.Add("bindpoint",$Bindpoint)}

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType csvserver_cspolicy_binding -ResourceName $Name -Arguments $args -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
