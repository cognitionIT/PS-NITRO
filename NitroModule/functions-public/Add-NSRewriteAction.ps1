    function Add-NSRewriteAction {
        <#
        .SYNOPSIS
            Add a Rewrite Action to the NetScalerConfiguration
        .DESCRIPTION
            Add a Rewrite Action to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER ActionName
            Name for the user-defined rewrite action.
        .PARAMETER ActionType
            Type of user-defined rewrite action. 
            Possible values = noop, delete, insert_http_header, delete_http_header, corrupt_http_header, 
            insert_before, insert_after, replace, replace_http_res, delete_all, replace_all, 
            insert_before_all, insert_after_all, clientless_vpn_encode, clientless_vpn_encode_all, 
            clientless_vpn_decode, clientless_vpn_decode_all, insert_sip_header, delete_sip_header, 
            corrupt_sip_header, replace_sip_res, replace_diameter_header_field, replace_dns_header_field, 
            replace_dns_answer_section
        .PARAMETER TargetExpression
            Default syntax expression that specifies which part of the request or response to rewrite. Minimum length = 1
        .PARAMETER Expression
            Default syntax expression that specifies the content to insert into the request or response at the specified location, or that replaces the specified string.
        .PARAMETER HeaderName
            Inserts the HTTP header specified by <header_string_builder_expr> and header contents specified by <contents_string_builder_expr>.
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
                if ($NSRewriteActionTypes -contains $_) 
                {
                    $true
                } 
                else 
                {
                    throw "Valid values are: $($NSRewriteActionTypes -join ', ')"
                }
            })] [string]$ActionType,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$TargetExpression,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Expression,
            [Parameter(Mandatory=$false)][ValidateScript({$ActionType -eq "insert_http_header"})] [string]$HeaderName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $payload = @{name=$ActionName;type=$ActionType;target=$TargetExpression;stringbuilderexpr=$Expression}

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType rewriteaction -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
