    function Update-NSResponderPolicy {
        <#
        .SYNOPSIS
            Add a Rewrite Policy to the NetScalerConfiguration
        .DESCRIPTION
            Add a Rewrite Policy to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name for the responder policy.
        .PARAMETER Rule
            Default syntax expression that the policy uses to determine whether to respond to the specified request.
        .PARAMETER Action
            Name of the responder action to perform if the request matches this responder policy.
        .PARAMETER UndefAction
            Action to perform if the result of policy evaluation is undefined (UNDEF). 
        .PARAMETER Comment
            Any type of information about this responder policy.
        .PARAMETER LogAction
            Name of the messagelog action to use for requests that match this policy.
        .PARAMETER AppflowAction
            AppFlow action to invoke for requests that match this policy.
        .EXAMPLE
            Update-NSRewritePolicy -NSSession $Session -PolicyName $PolicyName -PolicyAction $PolicyAction -PolicyRule "HTTP.REQ.URL.EQ(""/"")" -Comment "newly added"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$Name,
            [Parameter(Mandatory=$false)] [string]$Rule,
            [Parameter(Mandatory=$false)] [string]$Action,
            [Parameter(Mandatory=$false)] [string]$UndefAction,
            [Parameter(Mandatory=$false)] [string]$Comment,
            [Parameter(Mandatory=$false)] [string]$LogAction,
            [Parameter(Mandatory=$false)] [string]$AppflowAction
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $payload = @{name=$Name}
            If (!([string]::IsNullOrEmpty($Rule)))
            {
                $payload.Add("rule",$Rule)
            }
            If (!([string]::IsNullOrEmpty($Action)))
            {
                $payload.Add("action",$Action)
            }
            If (!([string]::IsNullOrEmpty($UndefAction)))
            {
                $payload.Add("undefaction",$UndefAction)
            }
            If (!([string]::IsNullOrEmpty($Comment)))
            {
                $payload.Add("comment",$Comment)
            }
            If (!([string]::IsNullOrEmpty($LogAction)))
            {
                $payload.Add("logaction",$LogAction)
            }
            If (!([string]::IsNullOrEmpty($AppflowAction)))
            {
                $payload.Add("appflowaction",$AppflowAction)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType responderpolicy -Payload $payload -Verbose:$VerbosePreference 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
