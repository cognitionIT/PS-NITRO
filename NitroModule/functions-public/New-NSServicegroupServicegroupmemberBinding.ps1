        function New-NSServicegroupServicegroupmemberBinding {
        #Updated 20160824: Removed unknown Action parameter
            <#
            .SYNOPSIS
                Retrieve a Service from the NetScalerConfiguration
            .DESCRIPTION
                Retrieve a Service from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the service group. Minimum length = 1
            .PARAMETER IP
                IP Address.
            .PARAMETER ServerName
                Name of the server to which to bind the service group. Minimum length = 1
            .PARAMETER Weight
                Weight to assign to the servers in the service group. Specifies the capacity of the servers relative to the other servers in the load balancing configuration. The higher the weight, the higher the percentage of requests sent to the service. Minimum value = 1. Maximum value = 100
            .PARAMETER port
                server port number. Range 1 - 65535
            .PARAMETER CustomserverId
                The identifier for this IP:Port pair. Used when the persistency type is set to Custom Server ID. Default value: "None"
            .PARAMETER ServerId
                The identifier for the service. This is used when the persistency type is set to Custom Server ID.
            .PARAMETER State
                Initial state of the service group. Default value: ENABLED. Possible values = ENABLED, DISABLED
            .PARAMETER hashid
                The hash identifier for the service. This must be unique for each service. This parameter is used by hash based load balancing methods. Minimum value = 1
            .EXAMPLE
                Get-NSService -NSSession $Session -Name $ServiceName
            .EXAMPLE
                Get-NSService -NSSession $Session
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
                [Parameter(Mandatory=$true,ParameterSetName='By Name')] [string]$ServerName,
                [Parameter(Mandatory=$true,ParameterSetName='By Address')] [string]$IPAddress,
                [Parameter(Mandatory=$false)][ValidateRange(1,100)] [double]$Weight,
                [Parameter(Mandatory=$true)] [ValidateRange(1,65535)] [int]$Port,
    #            [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$CustomServerId,
                [Parameter(Mandatory=$false)] [double]$ServerId,
                [Parameter(Mandatory=$true)][ValidateSet("ENABLED", "DISABLED")] [string]$State="ENABLED",
                [Parameter(Mandatory=$false)] [double]$HashId
            )
        
            Write-Verbose "$($MyInvocation.MyCommand): Enter"

            $payload = @{servicegroupname=$Name;port=$Port;state=$State}

            If ($ServerId) {$payload.Add("serverid",$ServerId)}
            If ($HashId) {$payload.Add("hashid",$HashId)}
            If ($Weight) {$payload.Add("weight",$Weight)}

            if ($PSCmdlet.ParameterSetName -eq 'By Name') {
                $payload.Add("servername",$ServerName)
            } elseif ($PSCmdlet.ParameterSetName -eq 'By Address') {
                Write-Verbose "Validating IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj)) {
                    throw "'$IPAddress' is an invalid IP address"
                }
                $payload.Add("ip",$IPAddress)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType servicegroup_servicegroupmember_binding -Payload $payload -Verbose:$VerbosePreference
   
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
