    # Send-NSLicenseViaPSCP is part of the Citrix NITRO Module
    # Copied from Citrix's Module to ensure correct scoping of variables and functions
    function Send-NSLicenseViaPSCP {    
        <#
        .SYNOPSIS
            Uploading the license file(s) to NetScaler appliance via Putty's PSCP
        .DESCRIPTION
            Uploading the license file(s) to license folder of NetScaler appliance. Destination file names are the same as source file names
        .Parameter NSIP
            NetScaler Management IPAddress
        .Parameter NSUserName
            UserName to access the NetScaler Managerment Console, default to nsroot
        .Parameter NSPassword
            Password to access the NetScaler Managerment Console, default to nsroot
        .Parameter PathToLicenseFile
            Full path to the source of the licenseFile, allow value from Pipeline
        .Parameter PathToPSCP
            Full path to pscp.exe. If this is not provided then the environment paths are used.
        .EXAMPLE
            Send two license files to NetScaler appliance with IPAddress 10.108.151.1
            $licfiles = @("C:\NSLicense\CAG_Enterprise_VPX_2012.lic","C:\NSLicense\CAGU-Hostname_10000CCU_sslvpn-sg.lic")
            $licfiles | Send-NSLicenseViaPSCP -NSIP 10.108.151.1
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)][string] $NSIP, 
            [Parameter(Mandatory=$false)][string] $NSUserName="nsroot", 
            [Parameter(Mandatory=$false)][string] $NSPassword="nsroot",
            [Parameter(Mandatory=$true,  ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] [string] $PathToLicenseFile,
            [Parameter(Mandatory=$false)] [string] $PathToPSCP
        )
        Begin {
            Write-Verbose "$($MyInvocation.MyCommand): Enter"

            if ([string]::IsNullOrEmpty($PathToPSCP)) {
                if (Get-Command "pscp.exe" -ErrorAction SilentlyContinue) {
                    $pscp = "pscp.exe"
                } else {
                    throw "Unable to find pscp.exe in the environment paths"
                }
            } else {
                if (-not $PathToPSCP.EndsWith("pscp") -or -not $PathToPSCP.EndsWith("pscp.exe")) {
                    $PathToPSCP = $PathToPSCP.TrimEnd("\") + "\pscp.exe"
                }
                if (Get-Command $PathToPSCP -ErrorAction SilentlyContinue) {
                    $pscp = $PathToPSCP
                } else {
                    throw "Unable to find pscp.exe at '$PathToPSCP'"
                }
            }
        }
        Process {
            Write-Verbose "Upload license file $PathToLicenseFile to NetScaler appliance '$NSIP'"
            $licenseFileName = Split-Path -Path $PathToLicenseFile -Leaf
            $argsList = @('-l',"$NSUserName",'-pw',"$NSPassword","-r","-p",$PathToLicenseFile,"$($NSIP):/nsconfig/license/$licenseFileName")
            if ($output = & $pscp $argsList ) {
                # Check the end-of-line for multi-file copies
                (($output -join "`n") -split "`n`n") | % {
                    if ( $_ -notmatch '100%\s*$' ) {
                        throw "Error occurred invoking 'pscp.exe $argsList' : $_"
                    }
                }
            }
        } 
        End {
            Write-Verbose "$($MyInvocation.MyCommand): Exit"
        }   
    }
