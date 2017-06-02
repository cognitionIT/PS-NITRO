    # Set-NSSFStore is part of the Citrix NITRO Module
    function Set-NSSFStore {
        <#
        .SYNOPSIS
            Configure NetScaler to work with an existing StoreFront Receiver for Web site.
        .DESCRIPTION
            Configure NetScaler to work with an existing StoreFront Receiver for Web site. That involves creating session policies and actions and bind them to the virtual server
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER NSUserName
            UserName to access the NetScaler Managerment Console, default to nsroot
        .PARAMETER NSPassword
            Password to access the NetScaler Managerment Console, default to nsroot
        .PARAMETER VirtualServerName
            Virtual Server Name
        .PARAMETER VirtualServerIP
            IPAddress of Virtual Server
        .PARAMETER StoreFrontServerURL
            URL including the name or IPAddress of the StoreFront Server
        .PARAMETER STAServerURL
            STA Server URL, usually the XenApp & XenDesktop Controllers
        .PARAMETER SingleSignOnDomain
            Single SignOn Domain Name, the same domain is used to autheticate to NetScaler Gateway and pass on to StoreFront
        .PARAMETER ReceiverForWebPath
            Path to the Receiver For Web Website
        .EXAMPLE
            Set-NSSFStore -NSSession $Session -VirtualServerName "SkynetVS" -VirtualServerIPAddress "10.108.151.3" -StoreFrontServerURL "https://10.108.156.7" -STAServerURL "https://10.108.156.7" -SingleSignOnDomain xd.local
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$NSUserName="nsroot", 
            [Parameter(Mandatory=$false)] [string]$NSPassword="nsroot",
            [Parameter(Mandatory=$true)] [string]$VirtualServerName,
            [Parameter(Mandatory=$true)] [string]$VirtualServerIPAddress,
            [Parameter(Mandatory=$true)] [string]$StoreFrontServerURL,
            [Parameter(Mandatory=$true)] [string[]]$STAServerURL,
            [Parameter(Mandatory=$true)] [string]$SingleSignOnDomain,
            [Parameter(Mandatory=$false)] [string]$ReceiverForWebPath="/Citrix/StoreWeb"
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        Add-NSVPNSessionAction -NSSession $NSSession -SessionActionName "AC_OS_$($VirtualServerIPAddress)_S_" -TransparentInterception "OFF" -SplitTunnel "OFF" `
        -DefaultAuthorizationAction "ALLOW" -SSO "ON" -IcaProxy "ON" -NTDomain $SingleSignOnDomain -ClientlessVpnMode "OFF" -ClientChoices "OFF" `
        -WIHome "$($StoreFrontServerURL.TrimEnd('/'))/$($ReceiverForWebPath.Trim('/'))" -StoreFrontUrl "$($StoreFrontServerURL.TrimEnd('/'))"

        Add-NSVPNSessionAction -NSSession $NSSession -SessionActionName "AC_WB_$($VirtualServerIPAddress)_S_" -TransparentInterception "OFF" -SplitTunnel "OFF" `
        -DefaultAuthorizationAction "ALLOW" -SSO "ON" -IcaProxy "ON" -NTDomain $SingleSignOnDomain -ClientlessVpnMode "OFF" -ClientChoices "OFF" `
        -WIHome "$($StoreFrontServerURL.TrimEnd('/'))/$($ReceiverForWebPath.Trim('/'))"

        Add-NSVPNSessionPolicy -NSSession $NSSession -SessionActionName "AC_OS_$($VirtualServerIPAddress)_S_" -SessionPolicyName "PL_OS_$($VirtualServerIPAddress)" `
        -SessionRuleExpression "REQ.HTTP.HEADER User-Agent CONTAINS CitrixReceiver || REQ.HTTP.HEADER Referer NOTEXISTS"

        Add-NSVPNSessionPolicy -NSSession $NSSession -SessionActionName "AC_WB_$($VirtualServerIPAddress)_S_" -SessionPolicyName "PL_WB_$($VirtualServerIPAddress)" `
        -SessionRuleExpression "REQ.HTTP.HEADER User-Agent NOTCONTAINS CitrixReceiver && REQ.HTTP.HEADER Referer EXISTS"

        New-NSVPNVServerSessionPolicyBinding -NSSession $NSSession -VirtualServerName $VirtualServerName -SessionPolicyName "PL_OS_$($VirtualServerIPAddress)" -Priority 100
        New-NSVPNVServerSessionPolicyBinding -NSSession $NSSession -VirtualServerName $VirtualServerName -SessionPolicyName "PL_WB_$($VirtualServerIPAddress)" -Priority 100

        $STAServerURL | New-NSVPNVServerSTAServerBinding -NSSession $NSSession -VirtualServerName $VirtualServerName

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
