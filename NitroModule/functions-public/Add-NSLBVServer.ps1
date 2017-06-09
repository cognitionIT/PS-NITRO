    # Add-NSLBVServer is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    # UPDATED with additional parameters
    function Add-NSLBVServer {
        <#
        .SYNOPSIS
            Add a new LB virtual server
        .DESCRIPTION
            Add a new LB virtual server
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the virtual server
        .PARAMETER Protocol
            Protocol used by the service (also called the service type).
        .PARAMETER IPAddressType
            Specifies whether a single IP address is provided or an IP pattern
        .PARAMETER IPAddress
            IPv4 or IPv6 address to assign to the virtual server
            Usually a public IP address. User devices send connection requests to this IP address
        .PARAMETER IPPattern
            IP address pattern, in dotted decimal notation, for identifying packets to be accepted by the virtual server. 
            The IP Mask parameter specifies which part of the destination IP address is matched against the pattern. 
            Mutually exclusive with the IP Address parameter.
        .PARAMETER IPMask
            IP mask, in dotted decimal notation, for the IP Pattern parameter. 
            Can have leading or trailing non-zero octets (for example, 255.255.240.0 or 0.0.255.255). 
            Accordingly, the mask specifies whether the first n bits or the last n bits of the destination IP address in a client request are to be matched with the corresponding bits in the IP pattern. 
            The former is called a forward mask. The latter is called a reverse mask.
        .PARAMETER ServiceType
            Protocol used by the service (also called the service type)
        .PARAMETER Port
            Port number for the virtual server
        .PARAMETER PersistenceType
            Type of persistence for the virtual server
        .PARAMETER LBMethod
            Load balancing method.
        .PARAMETER ClientTimeout
            Idle time, in seconds, after which a client connection is terminated.
        .PARAMETER Comment
            Any comments that you might want to associate with the virtual server.
        .EXAMPLE
            Add-NSLBVServer -NSSession $Session -Name "myLBVirtualServer" -IPAddress "10.108.151.3" -ServiceType "SSL" -Port 443 -PersistenceType "SOURCEIP"
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            [Parameter(Mandatory=$true)] [ValidateSet("HTTP","FTP","TCP","UDP","SSL","SSL_BRIDGE","SSL_TCP","DTLS","NNTP","DNS","DHCPRA","ANY",
            "SIP_UDP","SIP_TCP","SIP_SSL","DNS_TCP","RTSP","PUSH","SSL_PUSH","RADIUS","RDP","MYSQL","MSSQL","DIAMETER","SSL_DIAMETER","TFTP","ORACLE",
            "SMPP","SYSLOGTCP","SYSLOGUDP")] [string]$Protocol,
            [Parameter(Mandatory=$true)] [ValidateSet("IPAddress","IPPattern","NonAdressable")] [string]$IPAddressType,
            [Parameter(Mandatory=$true,ParameterSetName='IPAddress')][ValidateScript({$IPAddressType -eq "IPAddress"})] [string]$IPAddress,
            [Parameter(Mandatory=$true,ParameterSetName='IPPattern')][ValidateScript({$IPAddressType -eq "IPPattern"})] [string]$IPPattern,
            [Parameter(Mandatory=$true,ParameterSetName='IPPattern')][ValidateScript({$IPAddressType -eq "IPPattern"})] [string]$IPMask,
            [Parameter(Mandatory=$true)] [ValidateRange(1,65535)] [int]$Port,
            [Parameter(Mandatory=$false)] [ValidateSet("SOURCEIP","COOKIEINSERT","SSLSESSION","RULE","URLPASSIVE","CUSTOMSERVERID","DESTIP","SRCIPDESTIP",
            "CALLID","RTSPSID","DIAMETER","NONE")] [string]$PersistenceType,
            [Parameter(Mandatory=$false)] [ValidateSet("ROUNDROBIN","LEASTCONNECTION","LEASTRESPONSETIME","URLHASH","DOMAINHASH","DESTINATIONIPHASH",
            "SOURCEIPHASH","SRCIPDESTIPHASH","LEASTBANDWIDTH","LEASTPACKETS","TOKEN","SRCIPSRCPORTHASH","LRTM","CALLIDHASH","CUSTOMLOAD","LEASTREQUEST",
            "AUDITLOGHASH")] [string]$LBMethod="LEASTCONNECTION",
            [Parameter(Mandatory=$false)] [ValidateRange(0,31536000)] [double]$ClientTimeout,
            [Parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()] [string]$Comment
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
            $payload = @{name=$Name;servicetype=$Protocol}
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
            if (-not [string]::IsNullOrEmpty($PersistenceType)) {$payload.Add("persistencetype",$PersistenceType)}
            if (-not [string]::IsNullOrEmpty($LBMethod)) {$payload.Add("lbmethod",$LBMethod)}
            if (-not [string]::IsNullOrEmpty($Comment)) {$payload.Add("comment",$Comment)}

            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType lbvserver -Payload $payload 
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
