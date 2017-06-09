    function Add-NSRewritePolicy {
        <#
        .SYNOPSIS
            Add a Rewrite Policy to the NetScalerConfiguration
        .DESCRIPTION
            Add a Rewrite Policy to the NetScalerConfiguration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER PolicyName
            Name for the rewrite policy.
        .PARAMETER PolicyAction
            Name of the rewrite action to perform if the request or response matches this rewrite policy.
        .PARAMETER PolicyRule
            Expression against which traffic is evaluated.
        .PARAMETER Expression
            Default syntax expression that specifies the content to insert into the request or response at the specified location, or that replaces the specified string.
        .PARAMETER Comment
            Any comments that you might want to associate with the Rewrite Policy.
        .EXAMPLE
            Update-NSRewritePolicy -NSSession $Session -PolicyName $PolicyName -PolicyAction $PolicyAction -PolicyRule "HTTP.REQ.URL.EQ(""/"")" -Comment "newly added"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]  [string]$PolicyName,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$PolicyAction,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$PolicyRule,
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Comment
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $payload = @{name=$PolicyName;action=$PolicyAction;rule=$PolicyRule}
            If (!([string]::IsNullOrEmpty($Comment)))
            {
                $payload.Add("comment",$Comment)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType rewritepolicy -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
