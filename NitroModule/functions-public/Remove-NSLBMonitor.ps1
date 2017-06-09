        function Remove-NSLBMonitor{
            <#
            .SYNOPSIS
                Remove a NetScaler Monitor from the NetScalerConfiguration
            .DESCRIPTION
                Remove a NetScaler Monitor from the NetScalerConfiguration
            .PARAMETER NSSession
                An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
            .PARAMETER Name
                Name of the Monitor.
            .PARAMETER Type
                Type of monitor that you want to create.
            .EXAMPLE
                Remove-NSLBMonitor -NSSession $Session -Name $MonitorName
            .NOTES
                Copyright (c) cognition IT. All rights reserved.
            #>
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name,
                [Parameter(Mandatory=$true)] [ValidateSet(
                "PING","TCP","HTTP","TCP-ECV","HTTP-ECV","UDP-ECV","DNS","FTP","LDNS-PING","LDNS-TCP","LDNS-DNS","RADIUS","USER","HTTP-INLINE","SIP-UDP","LOAD","FTP-EXTENDED",
                "SMTP","SNMP","NNTP","MYSQL","MYSQL-ECV","MSSQL-ECV","ORACLE-ECV","LDAP","POP3","CITRIX-XML-SERVICE","CITRIX-WEB-INTERFACE","DNS-TCP","RTSP","ARP","CITRIX-AG",
                "CITRIX-AAC-LOGINPAGE","CITRIX-AAC-LAS","CITRIX-XD-DDC","ND6","CITRIX-WI-EXTENDED","DIAMETER","RADIUS_ACCOUNTING","STOREFRONT","APPC","CITRIX-XNC-ECV","CITRIX-XDM"
                )] [string]$Type
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
                $args=@{type=$Type}
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType lbmonitor -ResourceName $Name -Arguments $args -Verbose:$VerbosePreference
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
