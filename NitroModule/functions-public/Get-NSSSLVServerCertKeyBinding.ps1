    function Get-NSSSLVServerCertKeyBinding {
    # Created: 20160912
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
            [Parameter(Mandatory=$false)] [string]$VServerName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        If (-not [string]::IsNullOrEmpty($VServerName)) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType sslvserver_sslcertkey_binding -ResourceName $VServerName -Verbose:$VerbosePreference
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType sslvserver_sslcertkey_binding -Verbose:$VerbosePreference
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['sslvserver_sslcertkey_binding'])
        {
            return $response.sslvserver_sslcertkey_binding
        }
        else
        {
            return $null
        }
    }
