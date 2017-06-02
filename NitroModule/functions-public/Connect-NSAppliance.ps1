    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    function Connect-NSAppliance {
        <#
        .SYNOPSIS
            Connect to NetScaler Appliance
        .DESCRIPTION
            Connect to NetScaler Appliance. A custom web request session object will be returned
        .PARAMETER NSAddress
            NetScaler Management IP address
        .PARAMETER NSName
            NetScaler DNS name or FQDN
        .PARAMETER NSUserName
            UserName to access the NetScaler appliance
        .PARAMETER NSPassword
            Password to access the NetScaler appliance
        .PARAMETER Timeout
            Timeout in seconds to for the token of the connection to the NetScaler appliance. 900 is the default admin configured value.
        .EXAMPLE
             $Session = Connect-NSAppliance -NSAddress 10.108.151.1
        .EXAMPLE
             $Session = Connect-NSAppliance -NSName mynetscaler.mydomain.com
        .OUTPUTS
            CustomPSObject
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true,ParameterSetName='Address')] [string]$NSAddress,
            [Parameter(Mandatory=$true,ParameterSetName='Name')] [string]$NSName,
            [Parameter(Mandatory=$false)] [string]$NSUserName="nsroot", 
            [Parameter(Mandatory=$false)] [string]$NSPassword="nsroot",
            [Parameter(Mandatory=$false)] [int]$Timeout=900
        )
        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        if ($PSCmdlet.ParameterSetName -eq 'Address') {
            Write-Verbose "Validating IP Address"
            $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
            if (-not [System.Net.IPAddress]::TryParse($NSAddress,[ref]$IPAddressObj)) {
                throw "'$NSAddress' is an invalid IP address"
            }
            $nsEndpoint = $NSAddress
        } elseif ($PSCmdlet.ParameterSetName -eq 'Name') {
            $nsEndpoint = $NSName
        }


        $login = @{"login" = @{"username"=$NSUserName;"password"=$NSPassword;"timeout"=$Timeout}}
        $loginJson = ConvertTo-Json $login
    
        try {
            Write-Verbose "Calling Invoke-RestMethod for login"
            $response = Invoke-RestMethod -Uri "$($Script:NSURLProtocol)://$nsEndpoint/nitro/v1/config/login" -Body $loginJson -Method POST -SessionVariable saveSession -ContentType application/json
                
            if ($response.severity -eq "ERROR") {
                throw "Error. See response: `n$($response | fl * | Out-String)"
            } else {
                Write-Verbose "Response:`n$(ConvertTo-Json $response | Out-String)"
            }
        }
        catch [Exception] {
            throw $_
        }


        $nsSession = New-Object -TypeName PSObject
        $nsSession | Add-Member -NotePropertyName Endpoint -NotePropertyValue $nsEndpoint -TypeName String
        $nsSession | Add-Member -NotePropertyName WebSession  -NotePropertyValue $saveSession -TypeName Microsoft.PowerShell.Commands.WebRequestSession

        Write-Verbose "$($MyInvocation.MyCommand): Exit"

        return $nsSession
    }
