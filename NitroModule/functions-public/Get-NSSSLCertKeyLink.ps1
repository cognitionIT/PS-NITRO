    # Created: 20160906
    function Get-NSSSLCertKeyLink {
        <#
        .SYNOPSIS
            Retrieve certificate links
        .DESCRIPTION
            Retrieve certificate links
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER CertKeyName
            Name of the file to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSSLCertKeyLink -NSSession $Session -CertKeyName $name
        .EXAMPLE
            Get-NSSSLCertKeyLink -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$CertKeyName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

#        If (-not [string]::IsNullOrEmpty($CertKeyName)) {
#            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType sslcertlink -ResourceName $CertKeyName -Verbose:$VerbosePreference
#        }
#        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType sslcertlink -Verbose:$VerbosePreference
#        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['sslcertlink'])
        {
            return $response.sslcertlink
        }
        else
        {
            return $null
        }
    }
