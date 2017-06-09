    # Created: 20160905
    function Add-NSSystemFile {    
    <#
        .SYNOPSIS
            Uploading a file to the NetScaler Appliance
        .DESCRIPTION
            Uploading a file to the provided folder on the NetScaler Appliance. Destination file names are the same as source file names.
            N.B. This requires the Nitro Rest API version 10.5 or higher.
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER PathToFile
            Full path to the the file
        .PARAMETER NetScalerFolder
            Full path to the folder on the NetScaler Appliance to upload the file to
        .EXAMPLE
            Send two files to NetScaler appliance
            $licfiles = @("C:\NSLicense\CAG_Enterprise_VPX_2012.lic","C:\NSLicense\CAGU-Hostname_10000CCU_sslvpn-sg.lic")
            $licfiles | Send-NSLicense -NSSession $session -NetScalerFolder "/nsconfig/license"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession, 
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] [string]$PathToFile,
            [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$NetScalerFolder

        )
        Begin {        
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            Write-Verbose "Upload file '$PathToFile' to NetScaler '$($NSSession.Endpoint)$NetScalerFolder'"
            $FileName = Split-Path -Path $PathToFile -Leaf
            # Parameter explained: -Leaf     => Indicates that this cmdlet returns only the last item or container in the path. For example, in the path C:\Test\Logs\Pass1.log, it returns only Pass1.log.
        
            $FileContent = Get-Content $PathToFile -Encoding "Byte"
            $FileContentBase64 = [System.Convert]::ToBase64String($FileContent)

            $payload = @{filename=$FileName;filecontent=$FileContentBase64;filelocation=$NetScalerFolder;fileencoding="BASE64"}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemfile -Payload $payload
        } 
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }   
    }
