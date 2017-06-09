    function Update-NSRewriteAction {
        <#
        .SYNOPSIS
            Update a Rewrite Action to the NetScalerConfiguration
        .DESCRIPTION
            Update a Rewrite Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined rewrite action.
        .PARAMETER TargetExpression
            Default syntax expression that specifies which part of the request or response to rewrite. Minimum length = 1
        .PARAMETER Expression
            Default syntax expression that specifies the content to insert into the request or response at the specified location, or that replaces the specified string.
        .PARAMETER HeaderName
            Inserts the HTTP header specified by <header_string_builder_expr> and header contents specified by <contents_string_builder_expr>.
        .PARAMETER Comment
            Any comments that you might want to associate with the Rewrite Action.
        .EXAMPLE
            Update-NSRewriteAction -NSSession $Session -ActionName $ActionName -ActionType replace -TargetExpression "HTTP.REQ.URL" -Expression "\"/Citrix/XenApp\""
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$ActionName,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$TargetExpression,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Expression,
            [Parameter(Mandatory=$false)] [string]$HeaderName,
            [Parameter(Mandatory=$false)] [string]$Comment
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $payload = @{name=$ActionName;target=$TargetExpression;stringbuilderexpr=$Expression}
            If (!([string]::IsNullOrEmpty($Comment)))
            {
                $payload.Add("comment",$Comment)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType rewriteaction -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
