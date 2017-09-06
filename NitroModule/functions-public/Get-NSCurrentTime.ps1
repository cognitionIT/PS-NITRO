function Get-NSCurrentTime {
    <#
    .SYNOPSIS
        Retrieve the current NetScaler Time and returns as date object
    .DESCRIPTION
        Retrieve the current NetScaler Time and returns as date object
    .PARAMETER NSSession
        An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
    .EXAMPLE
        Get-NSCurrentTime -NSSession $Session
    .NOTES
        Author: Ryan Butler - Citrix CTA
        Date Created: 06/09/2017
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [PSObject]$NSSession
    )

    Write-Verbose "$($MyInvocation.MyCommand): Enter"
    $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType nsconfig -Verbose:$VerbosePreference
    $currentdatestr = ($response.nsconfig.currentsytemtime) -replace "  "," 0"
    $nsdate = [DateTime]::ParseExact($currentdatestr,"ddd MMM dd HH:mm:ss yyyy",$null)
    Write-Verbose "$($MyInvocation.MyCommand): Exit"
       
    return $nsdate
}