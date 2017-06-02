    function Remove-NSSystemFile {
    # Created: 20160905
        <#
        .SYNOPSIS
            Delete a file from a NetScaler Appliance
        .DESCRIPTION
            Delete a file from a NetScaler Appliance
        .PARAMETER NetScalerFolder
            Full path of the folder that hosts the file to be removed from the NetScaler Appliance
        .PARAMETER FileName
            Name of the file to be removed from the NetScaler Appliance
        .EXAMPLE
            Remove-NSSystemFile -NSSession $session -NetScalerFolder "/nsconfig/license/" -FileName $filename
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession, 
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$NetScalerFolder,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$FileName
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            $args = @{filelocation=$NetScalerFolder}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod DELETE -ResourceType systemfile -ResourceName $FileName -Arguments $args -Verbose:$VerbosePreference
        }
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }
    }
