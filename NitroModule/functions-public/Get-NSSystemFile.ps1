    function Get-NSSystemFile {
    # Created: 20160905
        <#
        .SYNOPSIS
            Retrieve system file resource(s) from the NetScaler configuration
        .DESCRIPTION
            Retrieve system file resource(s) from the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER FileName
            Name of the file to retrieve. Minimum length = 1
        .EXAMPLE
            Get-NSSystemFile -NSSession $Session -NetScalerFolder $folder -FileName $filename
        .EXAMPLE
            Get-NSSystemGroup -NSSession $Session -NetScalerFolder $folder
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$NetScalerFolder,
            [Parameter(Mandatory=$false)] [string]$FileName
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $args = @{filelocation=$NetScalerFolder}

        If (-not [string]::IsNullOrEmpty($FileName)) {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemfile -ResourceName $FileName -Arguments $args -Verbose:$VerbosePreference
        }
        Else {
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod GET -ResourceType systemfile -Arguments $args  -Verbose:$VerbosePreference
        }
        Write-Verbose "$($MyInvocation.MyCommand): Exit"
        If ($response.PSObject.Properties['systemfile'])
        {
            return $response.systemfile
        }
        else
        {
            return $null
        }
    }
