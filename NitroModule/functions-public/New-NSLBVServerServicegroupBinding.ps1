    function New-NSLBVServerServicegroupBinding {
    # Updated: 20160824 - Removed unknown Action parameter
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            # Name for the virtual server.
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            # The service group name bound to the selected load balancing virtual server
            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$ServiceGroupName
            # Service to bind to the virtual server.
#            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$ServiceName,
            # Integer specifying the weight of the service. Default value: 1. Minimum value = 1. Maximum value = 100
#            [Parameter(Mandatory=$false)][ValidateRange(1,100)] [int]$Weight
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name}
        }
        Process {
            if (-not [string]::IsNullOrEmpty($ServiceGroupName)) {$payload.Add("servicegroupname",$ServiceGroupName)}
#            if (-not [string]::IsNullOrEmpty($ServiceName)) {$payload.Add("servicename",$ServiceName)}
#            if ($Weight) {$payload.Add("weight",$Weight)}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType lbvserver_servicegroup_binding -Payload $payload
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
