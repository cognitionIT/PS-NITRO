    function New-NSLBVServerResponderPolicyBinding {
    # Updated: 20160824 - Removed unknown Action parameter
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            # Name for the virtual server
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$vServerName,
            # Name of the policy bound to the LB vserver
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$PolicyName,
            [Parameter(Mandatory=$true)] [double]$Priority,
            # Expression specifying the priority of the next policy which will get evaluated if the current policy rule evaluates to True
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$GotoPriorityExpression="END",
            # Invoke Label Type to select ("PolicyLabel", "Load Balancing Virtual Server", "Content Switching Virtual Server")
            [Parameter(Mandatory=$false)][ValidateSet("reqvserver","resvserver","policylabel")] [string]$InvokeLabelType
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"

            $payload = @{name=$vServerName;policyname=$PolicyName;priority=$Priority;bindpoint="REQUEST"}
        }
        Process {
#            if ($Invoke) {$payload.Add("invoke",$Invoke)}
            if (-not [string]::IsNullOrEmpty($GotoPriorityExpression)) {$payload.Add("gotopriorityexpression",$GotoPriorityExpression)}
            if (-not [string]::IsNullOrEmpty($InvokeLabelType)) {$payload.Add("labeltype",$InvokeLabelType)}

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType lbvserver_responderpolicy_binding -Payload $payload -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
