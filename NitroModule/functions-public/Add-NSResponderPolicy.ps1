    function Add-NSResponderPolicy {
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
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$Rule,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Action,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$UndefAction,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Comment,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$LogAction,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$AppflowAction
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $payload = @{name=$Name;rule=$Rule;action=$Action}
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

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType responderpolicy -Payload $payload -Verbose:$VerbosePreference 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
