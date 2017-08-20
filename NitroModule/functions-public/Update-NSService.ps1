        function Update-NSService{
            <#
            .SYNOPSIS
                Update a service resource
            .DESCRIPTION
                Update a service resource
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name for the service
            .PARAMETER ServerName
                Name of the server that hosts the service
            .PARAMETER ServerIPAddress
                IPv4 or IPv6 address of the server that hosts the service
                By providing this parameter, it attempts to create a server resource for you that's named the same as the IP address provided
            .PARAMETER Protocol
                Protocol in which data is exchanged with the service
            .PARAMETER Port
                Port number of the service
            .PARAMETER HealthMonitoring
                Monitor the health of this service. Available settings function as follows: YES - Send probes to check the health of the service. NO - Do not send probes to check the health of the service. With the NO option, the appliance shows the service as UP at all times. Default value: YES. Possible values = YES, NO
            .PARAMETER InsertClientIPHeader
                Before forwarding a request to the service, insert an HTTP header with the client's IPv4 or IPv6 address as its value
                Used if the server needs the client's IP address for security, accounting, or other purposes, and setting the Use Source IP parameter is not a viable option
            .PARAMETER ClientIPHeader
                Name for the HTTP header whose value must be set to the IP address of the client
                Used with the Client IP parameter
                If you set the Client IP parameter, and you do not specify a name for the header, the appliance uses the header name specified for the global Client IP Header parameter
                If the global Client IP Header parameter is not specified, the appliance inserts a header with the name "client-ip."
        .PARAMETER Comment
            Any comments that you might want to associate with the Service.
            .EXAMPLE
                Add-NSService -NSSession $Session -Name "Server1_Service" -ServerName "Server1" -ServerIPAddress "10.108.151.3" -Type "HTTP" -Port 80
            .NOTES
                Copyright (c) Citrix Systems, Inc. All rights reserved.
                Update 2018-08-20: Added the Healthmonitor parameter
            #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)] [string]$Name,
                [Parameter(Mandatory=$false,ParameterSetName='By Address')] [string]$ServerIPAddress,
                [Parameter(Mandatory=$false)] [ValidateSet("YES", "NO")] [string]$HealthMonitoring,
                [Parameter(Mandatory=$false)] [switch]$InsertClientIPHeader,
                [Parameter(Mandatory=$false)] [string]$ClientIPHeader,
                [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$Comment
            )

            Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
            $cip = if ($InsertClientIPHeader) { "ENABLED" } else { "DISABLED" }
            $payload = @{name=$Name;cip=$cip}
            If (!([string]::IsNullOrEmpty($HealthMonitoring)))
            {
                $payload.Add("healthmonitor",$HealthMonitoring)
            }
            if ($ClientIPHeader) {
                $payload.Add("cipheader",$ClientIPHeader)
            }
            if ($PSCmdlet.ParameterSetName -eq 'By Name') {
                $payload.Add("servername",$ServerName)
            } elseif ($PSCmdlet.ParameterSetName -eq 'By Address') {
                Write-Verbose "Validating IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($ServerIPAddress,[ref]$IPAddressObj)) {
                    throw "'$ServerIPAddress' is an invalid IP address"
                }
                $payload.Add("ip",$ServerIPAddress)
            }
            If (!([string]::IsNullOrEmpty($Comment)))
            {
                $payload.Add("comment",$Comment)
            }

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType service -Payload $payload  -Verbose:$VerbosePreference
   
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
    
        }
