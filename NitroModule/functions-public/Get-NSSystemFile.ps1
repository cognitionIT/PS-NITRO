    # Created: 20160905
    function Get-NSSystemFile {
        <#
        .SYNOPSIS
            Retrieve system file resource(s) from the NetScaler configuration
        .DESCRIPTION
            Retrieve system file resource(s) from the NetScaler configuration
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER NetScalerFolder
            The folder location on the NetScaler where the file resides
        .PARAMETER FileName
            Name of the file. It should not include filepath. Maximum length = 63
        .EXAMPLE
            Get-NSSystemFile -NSSession $NSSession -NetScalerFolder "/nsconfig/ssl/"
        .EXAMPLE
            Get-NSSystemFile -NSSession $NSSession -NetScalerFolder "/nsconfig/ssl/" | Where-Object {((($_.filename -like "*.cert") -or ($_.filename -like "*.cer") -or ($_.filename -like "*.der") -or ($_.filename -like "*.pfx")) -and ($_.filename -notlike "ns-*"))}
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
