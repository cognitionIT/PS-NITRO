    function Add-NSResponderAction {
        <#
        .SYNOPSIS
            Add a Responder Action to the NetScalerConfiguration
        .DESCRIPTION
            Add a Responder Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined responder action.
        .PARAMETER ActionType
            Type of user-defined responder action. 
            Possible values = noop, respondwith, redirect, respondwithhtmlpage, sqlresponse_ok, sqlresponse_error
        .PARAMETER TargetExpression
            Expression specifying what to respond with. Typically a URL for redirect policies or a default-syntax expression.
        .PARAMETER HTMLPage
            For respondwithhtmlpage policies, name of the HTML page object to use as the response. You must first import the page object. Minimum length=1
        .PARAMETER BypassSafetyCheck
            Bypass the safety check, allowing potentially unsafe expressions. Default value: NO. Possible values = YES, NO
        .PARAMETER ResponseStatusCode
            HTTP response status code, for example 200, 302, 404, etc. The default value for the redirect action type is 302 and for respondwithhtmlpage is 200. Minimum value = 100. Maximum value = 599
        .PARAMETER ReasonPhrase
            Expression specifying the reason phrase of the HTTP response. The reason phrase may be a string literal with quotes or a PI expression. For example: "Invalid URL: " + HTTP.REQ.URL.
        .PARAMETER Comment
            Any comments that you might want to associate with the Responder Action.
        .EXAMPLE
            Add-NSRewriteAction -NSSession $Session -ActionName $ActionName -ActionType replace -TargetExpression "HTTP.REQ.URL" -Expression "\"/Citrix/XenApp\""
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$ActionName,
            [Parameter(Mandatory=$true)][ValidateScript({
                if ($NSResponderActionTypes -contains $_) 
                {
                    $true
                } 
                else 
                {
                    throw "Valid values are: $($NSResponderActionTypes -join ', ')"
                }
            })] [string]$ActionType,
            [Parameter(Mandatory=$false)][string]$TargetExpression,
            [Parameter(Mandatory=$false)][ValidateScript({$ActionType -eq "respondwithhtmlpage"})] [string]$HTMLPage,
            [Parameter(Mandatory=$false)][ValidateSet("YES","NO")] [string]$BypassSafetyCheck="NO",
            [Parameter(Mandatory=$false)] [string]$Comment,
            [Parameter(Mandatory=$false)][ValidateRange(100,599)] [int]$ResponseStatusCode,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$ReasonPhrase
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $payload = @{name=$ActionName;type=$ActionType;bypasssafetycheck=$BypassSafetyCheck}

            if (-not [string]::IsNullOrEmpty($TargetExpression)) 
            {
               $payload.Add("target",$TargetExpression)
            }
            if (-not [string]::IsNullOrEmpty($HTMLPage)) 
            {
               $payload.Add("htmlpage",$HTMLPage)
            }
            if ($ResponseStatusCode) {
                $payload.Add("responsestatuscode",$ResponseStatusCode)
            }
            if (-not [string]::IsNullOrEmpty($Comment)) 
            {
               $payload.Add("comment",$Comment)
            }
            if (-not [string]::IsNullOrEmpty($ReasonPhrase)) 
            {
               $payload.Add("reasonphrase",$ReasonPhrase)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType responderaction -Payload $payload -Verbose:$VerbosePreference 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
