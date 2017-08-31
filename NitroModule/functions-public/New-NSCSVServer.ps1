    function New-NSCSVServer {
        <#
        .SYNOPSIS
            Add a new CS virtual server
        .DESCRIPTION
            Add a new CS virtual server
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name for the content switching virtual server.
        .PARAMETER ServiceType
            Protocol used by the virtual server.
            Possible values = HTTP, SSL, TCP, FTP, RTSP, SSL_TCP, UDP, DNS, SIP_UDP, SIP_TCP, SIP_SSL, ANY, RADIUS, RDP, MYSQL, MSSQL, DIAMETER, SSL_DIAMETER, DNS_TCP, ORACLE, SMPP
        .PARAMETER IPAddressType
            Specifies whether a single IP address is provided or an IP pattern
        .PARAMETER IPAddress
            IP address of the content switching virtual server.
        .PARAMETER IPPattern
            IP address pattern, in dotted decimal notation, for identifying packets to be accepted by the virtual server. 
            The IP Mask parameter specifies which part of the destination IP address is matched against the pattern. 
            Mutually exclusive with the IP Address parameter.
        .PARAMETER IPMask
            IP mask, in dotted decimal notation, for the IP Pattern parameter. 
            Can have leading or trailing non-zero octets (for example, 255.255.240.0 or 0.0.255.255). 
            Accordingly, the mask specifies whether the first n bits or the last n bits of the destination IP address in a client request are to be matched with the corresponding bits in the IP pattern. 
            The former is called a forward mask. The latter is called a reverse mask.
        .PARAMETER Port
            Port number for content switching virtual server. Minimum value = 1. Range 1 - 65535
        .PARAMETER State
            Initial state of the load balancing virtual server. Default value: ENABLED. Possible values = ENABLED, DISABLED
        .PARAMETER ClientTimeout
            Idle time, in seconds, after which the client connection is terminated. The default values are:
                180 seconds for HTTP/SSL-based services.
                9000 seconds for other TCP-based services.
                120 seconds for DNS-based services.
                120 seconds for other UDP-based services.
                Minimum value = 0. Maximum value = 31536000
        .PARAMETER Comment
            Any comments that you might want to associate with the virtual server.
        .EXAMPLE
            Add-NSCSVServer -NSSession $Session -Name "myCSVirtualServer" -IPAddress "10.108.151.3" -ServiceType "SSL" -Port 443
        .NOTES
            Version:        1.0
            Author:         Esther Barthel, MSc
            Creation Date:  2017-08-21

            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            [Parameter(Mandatory=$true)] [ValidateSet("HTTP","SSL","TCP","FTP","RTSP","SSL_TCP","UDP","DNS","SIP_UDP","SIP_TCP","SIP_SSL","ANY","RADIUS","RDP","MYSQL","MSSQL","DIAMETER","SSL_DIAMETER","DNS_TCP","ORACLE","SMPP")] [string]$ServiceType,
            [Parameter(Mandatory=$true)] [ValidateSet("IPAddress","IPPattern","NonAdressable")] [string]$IPAddressType,
            [Parameter(Mandatory=$true,ParameterSetName='IPAddress')][ValidateScript({$IPAddressType -eq "IPAddress"})] [string]$IPAddress,
            [Parameter(Mandatory=$true,ParameterSetName='IPPattern')][ValidateScript({$IPAddressType -eq "IPPattern"})] [string]$IPPattern,
            [Parameter(Mandatory=$true,ParameterSetName='IPPattern')][ValidateScript({$IPAddressType -eq "IPPattern"})] [string]$IPMask,
            [Parameter(Mandatory=$true)] [ValidateRange(1,65535)] [int]$Port,
            [Parameter(Mandatory=$false)] [ValidateSet("ENABLED","DISABLED")] [string]$State,
            [Parameter(Mandatory=$false)] [ValidateRange(0,31536000)] [double]$ClientTimeout,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$Comment
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name;servicetype=$ServiceType}
        }
        Process {
            if ($PSCmdlet.ParameterSetName -eq 'IPAddress') {
                Write-Verbose "Validating IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj)) {
                    throw "'$IPAddress' is an invalid IP address"
                }
                $payload.Add("ipv46",$IPAddress)
            } elseif ($PSCmdlet.ParameterSetName -eq 'IPPattern') {
                $payload.Add("ippattern",$IPPattern)
                $payload.Add("ipmask",$IPMask)
            }

            if ($Port) {$payload.Add("port",$Port)}
            if ($ClientTimeout) {$payload.Add("clttimeout",$ClientTimeout)}
            if (-not [string]::IsNullOrEmpty($State)) {$payload.Add("state",$State)}
            if (-not [string]::IsNullOrEmpty($Comment)) {$payload.Add("comment",$Comment)}

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType csvserver -Payload $payload 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
