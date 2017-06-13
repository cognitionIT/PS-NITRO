<#
.SYNOPSIS
  Citrix NetScaler VPX import script for ESX.
.DESCRIPTION
  Citrix NetScaler VPX import script for ESX importing the virtual appliance with a fixed IP.
.NOTES
  Version:        1.2
  Author:         Esther Barthel, MSc
  Creation Date:  2016-01-16

  Copyright (c) cognition IT. All rights reserved.

  Requires a local installation of PowerCLI Snapins for PowerShell

  Based upon Citrix Knowledgebase article: http://support.citrix.com/article/ctx128250
#>

# Constants
$VMDefaultName = "NSVPX-ESX"                               # Default name of NetScaler VPX
$FirstNICDefaultName = "Network adapter 1"                 # Default name of the first NIC
 
# vSphere variables
$vServer = "xxx.xxx.xxx.xxx"                               # IP address of the ESX host
$vAppSource = "C:\Install\NSVPX-ESX-11.0-63.16_nc.ovf"     # NetScaler OVF file to import
$ESXiHostName = "xxxxx"                                    # Name of the ESX(i) host
 
# VM variables
$VMName = "NSVPX-FixedIP"
$IPaddress = "10.1.1.231"
$SubnetMask = "255.255.255.0"
$DefaultGW = "10.1.1.1"
$VMNetworkName = "Internal Network"

# Optional VM variable (can be useful for NetScaler license management). The MAC address must be in the valid "manual" range 00:50:56:00:00:00 - 00:50:56:3F:FF:FF.    
$MACaddress = "00:50:56:34:05:58"
 
#Check version of PowerCLI and use appropiate method for adding cmdlets
If ((Get-Command Connect-ViServer -ErrorAction SilentlyContinue) -eq $null)
{
  $powercliVersion = $(Get-Module -ListAvailable | where {$_.name -match "VMware.VimAutomation.Core"}).Version.Major

  if ($powercliVersion -ge 6){
    import-module VMware.VimAutomation.Core
  }
  else {
    Add-PSSnapin VMware.VimAutomation.Core
  }
  Write-Verbose -Message "Adding the VMware.VimAutomation.Core PowerShell component..." -Verbose
}
 
# Connect to the vSphere server
Connect-VIServer -Server $vServer -WarningAction SilentlyContinue
 
# Import OVF on specified ESXi Host
$vmHost = Get-VMHost -Name $ESXiHostName
Import-vApp -Source $vAppSource -VMHost $vmHost -Force -WarningAction SilentlyContinue
 
# Get VM (based upon default name after import)
$VM = Get-VM -Name $VMDefaultName -Server $ESXiHostName
 
# Change the Network Adapter network
$VMFirstNIC = Get-NetworkAdapter -VM $VM | Where-Object {$_.Name -eq $FirstNICDefaultName}
 
If (($MACaddress -eq $null) -or ($MACaddress -eq ""))
{
    # Change the first Network adapter's Network (MAC address is auto generated)
    Set-NetworkAdapter $VMFirstNIC -NetworkName $VMNetworkName -Confirm:$false
}
Else
{
    # Change the first Network adapter's Network name and provide a fixed MAC address
    Set-NetworkAdapter $VMFirstNIC -NetworkName $VMNetworkName -MacAddress $MACaddress -Confirm:$false
}
# Change the VM name
Set-VM -VM $VM -Name $VMName -Confirm:$false
 
# Configure fixed IP for NetScaler
New-AdvancedSetting $VM -Type VM -Name "machine.id" -Value "ip=$IPaddress&netmask=$SubnetMask&gateway=$DefaultGW" -Confirm:$false -Force:$true -WarningAction SilentlyContinue
 
# Start VM
Start-VM $VM
 
# Disconnect from the vShpere Server 
Disconnect-VIServer -Server $vServer -Confirm:$false -WarningAction SilentlyContinue