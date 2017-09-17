    function New-NSCSVServerResponderPolicyBinding {
        <#
        .SYNOPSIS
            Bind a Responder Policy to a CS vServer
        .DESCRIPTION
            Bind a Responder Policy to a Content Switching vServer
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the content switching virtual server to which the content switching policy applies.
            Minimum length = 1
        .PARAMETER PolicyName
            Policy bound to this vserver.
        .PARAMETER TargetLBVServer
            Target vserver name
        .PARAMETER Priority
            Priority for the policy.
        .PARAMETER GotoPriorityExpression
            Expression specifying the priority of the next policy which will get evaluated if the current policy rule evaluates to TRUE.
        .PARAMETER Bindpoint
            The bindpoint to which the policy is bound. 
            Possible values = REQUEST, RESPONSE
        .PARAMETER Invoke
            Invoke flag.
        .PARAMETER Labeltype
            The invocation type.
            Possible values = reqvserver, resvserver, policylabel
        .PARAMETER Labelname
            Name of the label invoked
        .EXAMPLE
            New-NSCSVServerCSPolicyBinding -NSSession $Session -Name "cs_vsvr_http_https_redirection" -PolicyName "rspp_http_https_redirect" -Priority 100
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
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$PolicyName,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$TargetLBVserver,
            [Parameter(Mandatory=$false)] [int]$Priority,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$GotoPriorityExpression,
            [Parameter(Mandatory=$false)] [ValidateSet("REQUEST","RESPONSE")] [string]$Bindpoint,
            [Parameter(Mandatory=$false)] [switch]$Invoke,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$LabelType,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$LabelName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name}
        }
        Process {
            if (-not [string]::IsNullOrEmpty($PolicyName)) {$payload.Add("policyname",$PolicyName)}
            if (-not [string]::IsNullOrEmpty($TargetLBVserver)) {$payload.Add("targetvserver",$TargetLBVserver)}
            if (-not [string]::IsNullOrEmpty($GotoPriorityExpression)) {$payload.Add("gotopriorityexpression",$GotoPriorityExpression)}
            if (-not [string]::IsNullOrEmpty($Bindpoint)) {$payload.Add("bindpoint",$Bindpoint)}
            if (-not [string]::IsNullOrEmpty($LabelType)) {$payload.Add("labeltype",$LabelType)}
            if (-not [string]::IsNullOrEmpty($LabelName)) {$payload.Add("labelname",$LabelName)}
            if ($Priority) {$payload.Add("priority",$Priority)}
            if ($Invoke.ToBool()) {$payload.Add("invoke",$Invoke.ToBool())}

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType csvserver_responderpolicy_binding -Payload $payload 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
