    # Send-NSLicense is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    # Updated 20160912: Removed Action parameter to avoid errors
    function Send-NSLicense {    
        <#
        .SYNOPSIS
            Uploading the license file(s) to NetScaler Appliance
        .DESCRIPTION
            Uploading the license file(s) to license folder of NetScaler Appliance. Destination file names are the same as source file names.
            This requires the Nitro Rest API version 10.5 or higher.
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER PathToLicenseFile
            Full path to the the Citrix license file
        .EXAMPLE
            Send two license files to NetScaler appliance
            $licfiles = @("C:\NSLicense\CAG_Enterprise_VPX_2012.lic","C:\NSLicense\CAGU-Hostname_10000CCU_sslvpn-sg.lic")
            $licfiles | Send-NSLicense -NSSession $session
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession, 
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] [string]$PathToLicenseFile
        )
        Begin {        
            Write-Verbose "$($MyInvocation.MyCommand): Enter"
        }
        Process {
            Write-Verbose "Upload license file '$PathToLicenseFile' to NetScaler '$($NSSession.Endpoint)'"
            $licenseFileName = Split-Path -Path $PathToLicenseFile -Leaf
        
            if (-not $licenseFileName.EndsWith(".lic",[StringComparison]::OrdinalIgnoreCase)) {
                throw "'$licenseFileName' file name is invalid. Valid Citrix license file names end in .lic."
            }
        
            $licenseContent = Get-Content $PathToLicenseFile -Encoding "Byte"

            $licenseContentBase64 = [System.Convert]::ToBase64String($licenseContent)

            $payload = @{filename=$licenseFileName;filecontent=$licenseContentBase64;filelocation="/nsconfig/license/";fileencoding="BASE64"}
            $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType systemfile -Payload $payload 
        } 
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }   
    }
