function get-nslicenseexp {
<#
.SYNOPSIS
    Grabs Netscaler license expiration information via REST
.DESCRIPTION
    Grabs Netscaler license expiration information via REST.
.PARAMETER NSSession
    An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
.EXAMPLE
    Get-NSTime -NSSession $Session
.NOTES
    Author: Ryan Butler - Citrix CTA
    Date Created: 06/09/2017
#>
[CmdletBinding()]
param (
[Parameter(Mandatory=$true)] [PSObject]$NSSession
)
   
Write-Verbose "$($MyInvocation.MyCommand): Enter"
try {
    $lics = Get-NSSystemFile -NSSession $NSSession -NetScalerFolder "/nsconfig/license"|Where-Object {$_.filename -like "*.lic"}
}
Catch{
    throw "Error reading license(s)"
}
    
#Grabs current time from Netscaler
$currentnstime = Get-NSCurrentTime -NSSession $NSSession
 
$results = @()
foreach ($lic in $lics)
{
    Write-verbose "Reading $($lic.filename)"
        
    #Converts returned value from BASE64 to UTF8
    $lic = Get-NSSystemFile -NSSession $NSSession -NetScalerFolder "/nsconfig/license" -FileName $lic.filename
    $info = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($lic.filecontent))
        
    #Grabs needed line that has licensing information
    $lines = $info.Split("`n")|where-object{$_ -like "*INCREMENT*"}
    
#Parses needed date values from string
    $licdates = @()
    foreach ($line in $lines)
    {
        $licdate = $line.Split()
    
        if ($licdate[4] -like "permanent")
        {
            $expire = "PERMANENT"
        }
        else
        {
            $expire = [datetime]$licdate[4]
        }
    
        #adds date to object
        $temp = New-Object PSObject -Property @{
                    expdate = $expire
                    feature = $licdate[1]
                    }
        $licdates += $temp
    }
    
    foreach ($date in $licdates)
    {
        if ($date.expdate -like "PERMANENT")
        {
            $expires = "PERMANENT"
            $span = "9999"
        }
        else
        {
            $expires = ($date.expdate).ToShortDateString()
            $span = (New-TimeSpan -Start $currentnstime -end ($date.expdate)).days
        }
    
        $temp = New-Object PSObject -Property @{
            Expires = $expires
            Feature = $date.feature
            DaysLeft = $span
            LicenseFile = $lic.filename
            }
        $results += $temp    
    }    
    
}

Write-Verbose "$($MyInvocation.MyCommand): Exit"
return $results
}

