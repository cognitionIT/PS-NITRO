    function Get-NSSystemUser {
        <#
        .SYNOPSIS
            Retrieve the system user resource(s) from the NetScaler configuration
        .DESCRIPTION
            Retrieve the system user resource(s) from the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER UserName
            Name of the system user to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSystemUser -NSSession $Session -UserName user
        .EXAMPLE
            Get-NSSystemUser -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$false)] [string]$UserName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{}

        If (-not [string]::IsNullOrEmpty($UserName)) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemuser -ResourceName $UserName -Verbose:$VerbosePreference
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemuser -Verbose:$VerbosePreference
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['systemuser'])
        {
            return $response.systemuser
        }
        else
        {
            return $null
        }
    }
