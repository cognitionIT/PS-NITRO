    function Update-NSLBVServer {
        <#
        .SYNOPSIS
            Update a existing LB virtual server
        .DESCRIPTION
            Update a existing LB virtual server
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Name
            Name of the virtual server
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
        .PARAMETER PersistenceType
            Type of persistence for the virtual server
        .PARAMETER LBMethod
            Load balancing method.
        .PARAMETER ClientTimeout
            Idle time, in seconds, after which a client connection is terminated.
        .PARAMETER Comment
            Any comments that you might want to associate with the virtual server.
        .EXAMPLE
            Update-NSLBVServer -NSSession $Session -Name "vsvr_lb_storefront" -IPAddress "192.168.0.101"-PersistenceType "SOURCEIP" -LBMethod "ROUNDROBIN" -Comment "Updated the LB Method"
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
            [Parameter(Mandatory=$false)] [ValidateSet("IPAddress","IPPattern","NonAdressable")] [string]$IPAddressType,
            [Parameter(Mandatory=$false)][ValidateScript({$IPAddressType -eq "IPAddress"})] [string]$IPAddress,
            [Parameter(Mandatory=$false)][ValidateScript({$IPAddressType -eq "IPPattern"})] [string]$IPPattern,
            [Parameter(Mandatory=$false)][ValidateScript({$IPAddressType -eq "IPPattern"})] [string]$IPMask,
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
            $payload = @{name=$Name}
        }
        Process {
            if (-not [string]::IsNullOrEmpty($IPAddress)) {
                Write-Verbose "Validating IP Address"
                $IPAddressObj = New-Object -TypeName System.Net.IPAddress -ArgumentList 0
                if (-not [System.Net.IPAddress]::TryParse($IPAddress,[ref]$IPAddressObj)) {
                    throw "'$IPAddress' is an invalid IP address"
                }
                $payload.Add("ipv46",$IPAddress)
            } else {
                if (-not [string]::IsNullOrEmpty($IPPattern)) {$payload.Add("ippattern",$IPPattern)}
                if (-not [string]::IsNullOrEmpty($IPMask)) {$payload.Add("ipmask",$IPMask)}
            }
            if ($ClientTimeout) {$payload.Add("clttimeout",$ClientTimeout)}
            if (-not [string]::IsNullOrEmpty($PersistenceType)) {$payload.Add("persistencetype",$PersistenceType)}
            if (-not [string]::IsNullOrEmpty($LBMethod)) {$payload.Add("lbmethod",$LBMethod)}
            if (-not [string]::IsNullOrEmpty($Comment)) {$payload.Add("comment",$Comment)}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod PUT -ResourceType lbvserver -Payload $payload 
        }

        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
