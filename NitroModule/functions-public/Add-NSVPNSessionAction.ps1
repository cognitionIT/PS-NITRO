    # Add-NSVPNSessionAction is part of the Citrix NITRO Module
    function Add-NSVPNSessionAction {
        <#
        .SYNOPSIS
            Create VPN session action resource
        .DESCRIPTION
            Create VPN session action resource
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER SessionActionName
            Name for the session action
        .PARAMETER TransparentInterception
            Switch parameter. Allow access to network resources by using a single IP address and subnet mask or a range of IP addresses.
            When turned off,  sets the mode to proxy, in which you configure destination and source IP addresses and port numbers.
            If you are using the NetScale Gateway Plug-in for Windows, turn it on, in which the mode is set to transparent. 
            If you are using the NetScale Gateway Plug-in for Java, turn it off.
        .PARAMETER SplitTunnel
            Send, through the tunnel, traffic only for intranet applications that are defined in NetScaler Gateway. 
            Route all other traffic directly to the Internet.
            The OFF setting routes all traffic through Access Gateway. 
            With the REVERSE setting, intranet applications define the network traffic that is not intercepted.All network traffic directed to internal IP addresses bypasses the VPN tunnel, while other traffic goes through Access Gateway. 
            Reverse split tunneling can be used to log all non-local LAN traffic. 
            Possible values = ON, OFF, REVERSE
        .PARAMETER DefaultAuthorizationAction
            Specify the network resources that users have access to when they log on to the internal network. Acceptable vaules: "ALLOW","DENY"
            Default to "DENY", which deny access to all network resources. 
        .PARAMETER SSO,
            Set single sign-on (SSO) for the session. When the user accesses a server, the user's logon credentials are passed to the server for authentication.
            Acceptable values: "ON","OFF", default to 'ON"
        .PARAMETER IcaProxy
            Enable ICA proxy to configure secure Internet access to servers running Citrix XenApp or XenDesktop by using Citrix Receiver instead of the Access Gateway Plug-in.
        .PARAMETER NtDomain
            Single sign-on domain to use for single sign-on to applications in the internal network. 
            This setting can be overwritten by the domain that users specify at the time of logon or by the domain that the authentication server returns.
        .PARAMETER ClientlessVpnMode
            Enable clientless access for web, XenApp or XenDesktop, and FileShare resources without installing the Access Gateway Plug-in. 
            Available settings function as follows: * ON - Allow only clientless access. * OFF - Allow clientless access after users log on with the Access Gateway Plug-in. * DISABLED - Do not allow clientless access.
        .PARAMETER ClientChoices
            Provide users with multiple logon options. With client choices, users have the option of logging on by using the Access Gateway Plug-in for Windows, Access Gateway Plug-in for Java, the Web Interface, or clientless access from one location.
            Depending on how Access Gateway is configured, users are presented with up to three icons for logon choices. The most common are the Access Gateway Plug-in for Windows, Web Interface, and clientless access.
        .PARAMETER StoreFrontUrl,
            Web address for StoreFront to be used in this session for enumeration of resources from XenApp or XenDesktop.
        .PARAMETER WIHome
            Web address of the Web Interface server, such as http:///Citrix/XenApp, or Receiver for Web, which enumerates the virtualized resources, such as XenApp, XenDesktop, and cloud applications.
        .EXAMPLE
            Add-NSVPNSessionAction -NSSession $Session -SessionActionName AC_OS_10.108.151.1_S_ -NTDomain xd.local -WIHome "http://10.8.115.243/Citrix/StoreWeb" -StoreFrontUrl "http://10.8.115.243"
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string]$SessionActionName,
            [Parameter(Mandatory=$false)] [ValidateSet("ON","OFF")] [string]$TransparentInterception="OFF",
            [Parameter(Mandatory=$false)] [ValidateSet("ON","OFF","REVERSE")] [string]$SplitTunnel="OFF",
            [Parameter(Mandatory=$false)] [ValidateSet("ALLOW","DENY")] [string]$DefaultAuthorizationAction="ALLOW",
            [Parameter(Mandatory=$false)] [ValidateSet("ON","OFF")] [string]$SSO="ON",
            [Parameter(Mandatory=$false)] [ValidateSet("ON","OFF")] [string]$IcaProxy="ON",
            [Parameter(Mandatory=$true)] [string]$NTDomain,
            [Parameter(Mandatory=$false)] [ValidateSet("ON","OFF","DISABLED")] [string]$ClientlessVpnMode="OFF",
            [Parameter(Mandatory=$false)] [ValidateSet("ON","OFF")] [string]$ClientChoices="OFF",
            [Parameter(Mandatory=$false)] [string]$StoreFrontUrl,
            [Parameter(Mandatory=$false)] [string]$WIHome="$StoreFrontUrl/Citrix/StoreWeb"
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $payload = @{
            name = $SessionActionName
            transparentinterception = $TransparentInterception
            splittunnel = $SplitTunnel
            defaultauthorizationaction = $DefaultAuthorizationAction
            SSO = $SSO
            icaproxy = $IcaProxy
            wihome = $WIHome
            clientchoices = $ClientChoices
            ntdomain = $NTDomain
            clientlessvpnmode=$ClientlessVpnMode
        }
        if (-not [string]::IsNullOrEmpty($StoreFrontUrl)) {
            $payload.Add("storefronturl",$StoreFrontUrl)
        }
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType vpnsessionaction -Payload $payload -Action add 

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
