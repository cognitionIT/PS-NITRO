<#
.SYNOPSIS
  Citrix NetScaler VPX import script for ESX.
.DESCRIPTION
  Citrix NetScaler VPX import script for ESX importing the virtual appliance with a fixed IP.
.NOTES
  Version:        1.1
  Author:         Esther Barthel, MSc
  Creation Date:  2015-11-15

  Copyright (c) cognition IT. All rights reserved.

  Requires a local installation of the XenServer PowerShell Module (SDK)

  Based upon CTX article: http://support.citrix.com/article/CTX128236
#>

# Import XenServer 6.5.1 SDK
Import-Module "C:\Install\XenServerPSModule"

# Configure script variables
$XSServer = "192.168.10.51"                                    # Hostname or IP-address of XenServer Poolmaster
$sourcePath = "C:\Install\NSVPX-XEN-11.0-63.16_nc.xva"         # location of NS VPX image on machine running PowerShell
$nsIPAddress = "192.168.10.6"                                  # fixed IP-address to configure for the NetScaler VPX
$nsNetmask = "255.255.255.0"                                   # Netmask to configure for the NetScaler VPX
$nsGateway = "192.168.10.1"                                    # Default Gateway to configure for the NetScaler VPX
$XSHost = "HLXS01"                                             # The XenServer Host the VM is started on
$VMName = "NSNitro"                                            # The new name of the VM
$VMMACAddress = "1e:71:8a:76:f1:6e"                            # The new MAC Address to be given to the VM 1e718a76f16e
$Networklabel = "Storage Network 10 (NIC1)"

# Open a connection to XenServer (poolmaster) and make it the default session (required)
$oXSSession = Connect-XenServer -Server $XSServer -SetDefaultSession

# Import the NetScaler image to the default SR
Import-XenVm -XenHost $XSServer -Path $sourcePath -Verbose

# Get the imported NS VPX VM uuid by it's default name
$oVM = Get-XenVM -Name "NetScaler Virtual Appliance"

# Change the MAC address of the VM if a MAC address was specified
If (!(($VMMACaddress -eq $null) -or ($VMMACaddress -eq "")))
{
    # Retrieve the current VIF object from the specified VM object
    $oVIF = Get-XenVIF | Where-Object {$_.VM -eq $oVM}
    # Retrieve the Network object from the specified Network label
    $oNetwork = Get-XenNetwork -Name $Networklabel
    # Remove the automatically assigned VIF
    Remove-XenVIF -VIF $oVIF
    # Create a new VIF for the give Network and VM objects with a specified MAC Address
    New-XenVIF -VM $oVM -Network $oNetwork -MAC $VMMACAddress -Device "1"
}

# Change the name of the VM and make it start on the specified XS Host
$oXS = Get-XenHost -Name $XSHost
Set-XenVM -Uuid $oVM.uuid -NameLabel $VMName -Affinity $oXS

# Get current VM XenStoreData values
$newHash = $oVM.xenstore_data

# Add required values for fixed IP settings for the NetScaler VPX
$newHash.add("vm-data/ip",$nsIPAddress)
$newHash.add("vm-data/netmask",$nsNetmask)
$newHash.add("vm-data/gateway",$nsGateway)

# Add new values to current VM XenStoreData (works only once, before NS is booted)
Set-XenVM -VM $oVM -XenstoreData $newHash

# Start the NS Appliance
Invoke-XenVM $oVM -XenAction Start

# Disconnect the session
Get-XenSession -Server $XSServer | Disconnect-XenServer
