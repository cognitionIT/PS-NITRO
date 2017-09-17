    function New-NSCSPolicy {
        <#
        .SYNOPSIS
            Add a new CS Policy
        .DESCRIPTION
            Add a new CS Policy
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name for the content switching Policy.
        .PARAMETER URL
            URL string that is matched with the URL of a request. Can contain a wildcard character. Specify the string value in the following format: [[prefix] [*]] [.suffix].
            Minimum length = 1
            Maximum length = 208
        .PARAMETER Rule
            Expression, or name of a named expression, against which traffic is evaluated. Written in the classic or default syntax. 
            Note:
            Maximum length of a string literal in the expression is 255 characters. A longer string can be split into smaller strings of up to 255 characters each, and the smaller strings concatenated with the + operator. For example, you can create a 500-character string as follows: '"<string of 255 characters>" + "<string of 245 characters>"'
            The following requirements apply only to the NetScaler CLI:
            * If the expression includes one or more spaces, enclose the entire expression in double quotation marks.
            * If the expression itself includes double quotation marks, escape the quotations by using the character. 
            * Alternatively, you can use single quotation marks to enclose the rule, in which case you do not have to escape the double quotation marks.
        .PARAMETER Domain
            The domain name. The string value can range to 63 characters.
            Minimum length = 1
        .PARAMETER Action
            Content switching action that names the target load balancing virtual server to which the traffic is switched.
        .PARAMETER LogAction
            The log action associated with the content switching policy.
        .EXAMPLE
            New-NSCSPolicy -NSSession $Session -Name "myCSPolicy" -Rule "HTTP.REQ.HOSTNAME.SET_TEXT_MODE(IGNORECASE).EQ(""nsg.demo.lab"")" -ACtion "cs_act_unifiedgateway"
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
