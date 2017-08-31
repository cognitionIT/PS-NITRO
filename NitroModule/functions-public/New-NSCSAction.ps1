    function New-NSCSAction {
        <#
        .SYNOPSIS
            Add a new CS Action
        .DESCRIPTION
            Add a new CS Action
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name for the content switching action.
        .PARAMETER TargetLBVServer
            Name of the load balancing virtual server to which the content is switched.
        .PARAMETER TargetVServer
            Name of the VPN virtual server to which the content is switched.
        .PARAMETER TargetVServerExpression
            Information about this content switching action.
        .PARAMETER Comment
            Any comments that you might want to associate with the content switching action.
        .EXAMPLE
            New-NSCSAction -NSSession $Session -Name "myCSAction" -TargetLBVServer "myLBVServer
        .NOTES
            Version:        1.0
            Author:         Esther Barthel, MSc
            Creation Date:  2017-08-30

            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            [Parameter(Mandatory=$false,ParameterSetName='LoadBalancing')] [ValidateNotNullOrEmpty()] [string]$TargetLBVServer,
            [Parameter(Mandatory=$false,ParameterSetName='Gateway')] [ValidateNotNullOrEmpty()] [string]$TargetVServer,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$TargetVServerExpression,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$Comment
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name}
        }
        Process {
            if ($PSCmdlet.ParameterSetName -eq 'LoadBalancing') {
                $payload.Add("targetlbvserver",$TargetLBVServer)
            } elseif ($PSCmdlet.ParameterSetName -eq 'Gateway') {
                $payload.Add("targetvserver",$TargetVServer)
            }

            if (-not [string]::IsNullOrEmpty($TargetVServerExpression)) {$payload.Add("targetvserverexpr",$TargetVServerExpression)}
            if (-not [string]::IsNullOrEmpty($Comment)) {$payload.Add("comment",$Comment)}

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType csaction -Payload $payload 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
