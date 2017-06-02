    function Remove-NSLBVServerResponderPolicyBinding {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            # vServer name
            [Parameter(Mandatory=$true)] [string]$Name,
            [Parameter(Mandatory=$true)] [string]$PolicyName,
            [Parameter(Mandatory=$false)] [string]$BindPoint,
            [Parameter(Mandatory=$false)] [double]$Priority
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $args=@{policyname=$PolicyName}
            If ($Priority) {$payload.Add("priority",$Priority)}
            If (-not [string]::IsNullOrEmpty($BindPoint)){$payload.Add("bindpoint",$BindPoint)}
        }
        Process {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType lbvserver_responderpolicy_binding -ResourceName $Name -Arguments $args -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
