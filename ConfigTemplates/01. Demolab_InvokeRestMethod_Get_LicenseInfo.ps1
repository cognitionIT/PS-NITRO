<#
.SYNOPSIS
  Get NetScaler VPX License information.
.DESCRIPTION
  Get NetScaler VPX license information, using the Invoke-RestMethod cmdlet for the REST API calls.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-08-15
  Purpose:        Created to quickly some information script

  Copyright (c) cognition IT. All rights reserved.
#>

#region NITRO settings
    #region Test Environment variables
        $TestEnvironment = "demo"

        Switch ($TestEnvironment)
        {
            "Elektra" 
            {
                $RootFolder = "H:\PSModules\NITRO\Scripts"
                $SubnetIP = "192.168.59"
            }
            default
            {
                $RootFolder = "C:\Scripts\NITRO"
                $SubnetIP = "192.168.0"
            }
        }
        $NSLicFile = $RootFolder + "\NSVPX-ESX_PLT_201609.lic"

        # What to install (for script testing purposes)
        $ConfigNSGSettings = $true
    #endregion Test Environment variables
    $ContentType = "application/json"
    $NSIP = $SubNetIP + ".2"
    # Build my own credentials variable, based on password string
    $PW = ConvertTo-SecureString "nsroot" -AsPlainText -Force
    $MyCreds = New-Object System.Management.Automation.PSCredential ("nsroot", $PW)
#    $FileRoot = "C:\GitHub\PS-NITRO_v20170509\Scripts_InvokeRestMethod"
    $FileRoot = "C:\GitHub\PS-NITRO\Scripts_InvokeRestMethod"

#    $HTTPConnection = "https"
    $HTTPConnection = "http"
     
    #region Force PowerShell to trust the NetScaler (self-signed) certificate
    If ($HTTPConnection = "https")
    {
        Write-Verbose "Forcing PowerShell to trust all certificates (including the self-signed netScaler certificate)"
        # set communication protocol
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls
        # source: https://blogs.technet.microsoft.com/bshukla/2010/04/12/ignoring-ssl-trust-in-powershell-system-net-webclient/ 
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    }
    #endregion

    $NSUserName = "nsroot"
    $NSUserPW = "nsroot"

    $strDate = Get-Date -Format yyyyMMddHHmmss
#endregion NITRO settings

Write-Host "------------------------------------------- " -ForegroundColor Yellow
Write-Host "| NetScaler Configuration with NITRO:     | " -ForegroundColor Yellow
Write-Host "------------------------------------------- " -ForegroundColor Yellow

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

# ----------------------------------------
# | Method #1: Using the SessionVariable |
# ----------------------------------------
#region Start NetScaler NITRO Session
    #Connect to the NetScaler VPX
    $Login = @{"login" = @{"username"=$NSUserName;"password"=$NSUserPW;"timeout"=”900”}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "$HTTPConnection`://$NSIP/nitro/v1/config/login" -Body $Login -Method POST -SessionVariable NetScalerSession -ContentType $ContentType -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion Start NetScaler NITRO Session

# -------------------------
# | Get License file info |
# -------------------------

#region Check for license files
<#
    get (all)
    URL:http://<netscaler-ip-address>/nitro/v1/config/systemfile
    Query-parameters:
    args
    http://<netscaler-ip-address>/nitro/v1/config/systemfile?args=filename:<String_value>,filelocation:<String_value>
        Use this query-parameter to get systemfile resources based on additional properties.
    HTTP Method:GET
    Request Headers:

    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Accept:application/json

    Response:

    HTTP Status Code on Success: 200 OK
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error

    Response Header:

    Content-Type:application/json

    Response Payload:

    { "systemfile": [ {
    filename:<String_value>,filelocation:<String_value>      "filecontent":<String_value>,
          "fileencoding":<String_value>,
          "fileaccesstime":<String_value>,
          "filemodifiedtime":<String_value>,
          "filemode":<String[]_value>,
          "filesize":<Double_value>
    }]}
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/systemfile"

    # Creating the right payload formatting (mind the Depth for the nested arrays)

    # Get FileName, Content and Base64 String from the FilePath, Keep in mind that the filenames are case-sensitive
    $PathToFile = $FileRoot + "\Certificates\rootCA.cer"
    $File1Name = Split-Path -Path $PathToFile -Leaf                                                 # Parameter explained: -Leaf     => Indicates that this cmdlet returns only the last item or container in the path. For example, in the path C:\Test\Logs\Pass1.log, it returns only Pass1.log.
    $FileContent = Get-Content $PathToFile -Encoding "Byte"
    $File1ContentBase64 = [System.Convert]::ToBase64String($FileContent)

    $PathToFile = $FileRoot + "\Certificates\Wildcard.pfx"
    $File2Name = Split-Path -Path $PathToFile -Leaf                                                 # Parameter explained: -Leaf     => Indicates that this cmdlet returns only the last item or container in the path. For example, in the path C:\Test\Logs\Pass1.log, it returns only Pass1.log.
    $FileContent = Get-Content $PathToFile -Encoding "Byte"
    $File2ContentBase64 = [System.Convert]::ToBase64String($FileContent)

    $payload = @{
        "systemfile"= @(
            @{"filename"=$File1Name; "filecontent"=$File1ContentBase64; "filelocation"="/nsconfig/ssl/"; "fileencoding"="BASE64"},
            @{"filename"=$File2Name; "filecontent"=$File2ContentBase64; "filelocation"="/nsconfig/ssl/"; "fileencoding"="BASE64"}
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorVariable restError
#endregion Upload certificate





#region End NetScaler NITRO Session
    # restore SSL validation to normal behavior
    If ($HTTPConnection = "https")
    {
        Write-Verbose "Resetting Certificate Validation to default behavior"
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
    }
    #Disconnect from the NetScaler VPX
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session

