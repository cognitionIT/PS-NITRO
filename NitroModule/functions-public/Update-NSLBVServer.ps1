    function Update-NSLBVServer {
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
