    function Get-NSLBVServerServicegroupBinding {
        <#
        .SYNOPSIS
            Retrieve NetScaler vServer ServiceGroup Binding
        .DESCRIPTION
            Retrieve NetScaler vServer ServiceGroup Binding
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the Load Balancing vServer.
        .EXAMPLE
            Get-NSLBVServerServicegroupBinding -NSSession $Session -Name vsvr_lb_storefront
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$Name
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            If ($Name){
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType lbvserver_servicegroup_binding -ResourceName $Name
            }
            Else {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType lbvserver_servicegroup_binding
            }
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
            If ($response.PSObject.Properties['lbvserver_servicegroup_binding'])
            {
                return $response.lbvserver_servicegroup_binding
            }
            else
            {
                return $null
            }
        }
    }
