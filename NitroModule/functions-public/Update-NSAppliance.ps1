#Will probably fail with VPX Express due to timeout while downloading firmware
function Update-NSAppliance {
    <#
    .SYNOPSIS
        Grabs Netscaler license expiration information via REST
    .DESCRIPTION
        Grabs Netscaler license expiration information via REST.
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .PARAMETER url
        URL for Netscaler firmware (MANDATORY)
    .PARAMETER noreboot
        Don't reboot after upgrade
    .PARAMETER nocallhome
        Don't enable CallHome
    .EXAMPLE
        Update-NSAppliance -NSSession $Session -url "https://mywebserver/build-11.1-47.14_nc.tgz"
    .NOTES
        Author: Ryan Butler - Citrix CTA
        Date Created: 06/09/2017
    #>
    [CmdletBinding()]
    param (
    [Parameter(Mandatory=$true)] [PSObject]$NSSession,
    [Parameter(Mandatory=$true)] $url,
    [switch]$noreboot,
    [switch]$nocallhome
    )
    Write-Verbose "$($MyInvocation.MyCommand): Enter"

    if(!$nocallhome)
    {
       write-verbose "Enabling callhome"
       $ch = $true
    }
    else
    {
        write-verbose"Disabling callhome"
        $ch = $false
    }

    if(!$noreboot)
    {
        Write-Verbose "Rebooting NS Appliance"
        $reboot = $true
    }
    else
    {
        Write-Verbose "Skipping reboot"
        $reboot = $false
    }

    #Build upgrade payload
    $payload = @{
            "url" = $url;
            "y" = $reboot;
            "l" = $ch;
            }
    
    #Attempt upgrade
    try{
        Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType install -Verbose:$VerbosePreference -payload $payload
    }
    Catch{
        throw $_
    }
    
    
    Write-Verbose "$($MyInvocation.MyCommand): Exit"
}