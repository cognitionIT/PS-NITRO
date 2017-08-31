    function New-NSCVServerCSPolicyBinding {
        <#
        .SYNOPSIS
            Bind a CS Policy to a CS vServer
        .DESCRIPTION
            Bind a CS Policy to a Content Switching vServer
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name for the content switching Policy.
        .PARAMETER PolicyName

        .PARAMETER TargetLBVServer

        .PARAMETER Priority

        .PARAMETER GotoPriorityExpression

        .PARAMETER Bindpoint

        .PARAMETER Invoke

        .PARAMETER Labeltype

        .PARAMETER Labelname

        .EXAMPLE
            New-NSCSVServerCSPolicyBinding -NSSession $Session Name ="cs_vsvr_one_url_test"; "policyname"="cs_pol_gateway"; "priority"=100
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
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$URL,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$Rule,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$Domain,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$Action,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$LogAction
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{policyname=$Name}
        }
        Process {
            if (-not [string]::IsNullOrEmpty($URL)) {$payload.Add("url",$URL)}
            if (-not [string]::IsNullOrEmpty($Rule)) {$payload.Add("rule",$Rule)}
            if (-not [string]::IsNullOrEmpty($Domain)) {$payload.Add("domain",$Domain)}
            if (-not [string]::IsNullOrEmpty($Action)) {$payload.Add("action",$Action)}
            if (-not [string]::IsNullOrEmpty($LogAction)) {$payload.Add("logaction",$LogAction)}

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType cspolicy -Payload $payload 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
