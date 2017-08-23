<#
.SYNOPSIS
  Configure Basic SAML Authentication on the NetScaler VPX.
.DESCRIPTION
  Configure Basic SAML Authentication on the NetScaler VPX, using the Invoke-RestMethod cmdlet for the REST API calls.
.NOTES
  Version:        1.0
  Author:         Esther Barthel, MSc
  Creation Date:  2017-07-18
  Purpose:        Created to quickly test FAS supporting configs

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
        $CertFolder = "C:\Input\Certificates"
        $NSLicFile = "C:\Input\LicenseFiles\NSVPX-ESX_PLT_201609.lic"

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

    $NSUserName = "nsroot"
    $NSUserPW = "nsroot"

    $strDate = Get-Date -Format yyyyMMddHHmmss
#endregion NITRO settings

Write-Host "--------------------------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Pushing the FAS configuration for NetScaler with NITRO:     | " -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------- " -ForegroundColor Yellow

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
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/login" -Body $Login -Method POST -SessionVariable NetScalerSession -ContentType $ContentType -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion Start NetScaler NITRO Session

# -------------------------------------
# | Enable require NetScaler Features |
# -------------------------------------
#region Enable NetScaler Basic & Advanced Features
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/nsfeature?action=enable"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # enable ns feature CS GSLB

    $payload = @{
    "nsfeature"= @{
        "feature"=@("SSLVPN")
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Enable NetScaler Basic & Advanced Features

# ----------------------------------------------
# | Retrieve certificate file from ADFS Server |
# ----------------------------------------------
# source: https://social.technet.microsoft.com/Forums/windows/en-US/30622284-14ce-4c11-a1be-18e32fca6581/how-do-i-get-to-use-the-adfs-powershell-cmdlets-in-server-2012-r2?forum=winserverpowershell
#region Retrieve ADFS Signing certificate
    # retrieving the certificate on the ADFS Serveer
#    $IDPSigningCertRef = Get-ADFSCertificate -CertificateType Token-Signing

    # read the current certificate  information
#    $IDPSigningCertBytes = $IDPSigningCertRef[0].Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)

    # save the certificate to file
#    [System.IO.File]::WriteAllBytes("$FileRoot\Certificates\IDPCert.cer",$IDPSigningCertBytes)
#endregion Retrieve ADFS Signing certificate

# ----------------------------------------
# | Upload certificate file to NetScaler |
# ----------------------------------------
#region Upload certificates
    <#
        add
        URL:http://<netscaler-ip-address>/nitro/v1/config/systemfile
        Query-parameters:
        override=<String_value>
        HTTP Method:POST
        Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
        Request Payload:
        {"systemfile":{
              "filename":<String_value>,
              "filecontent":<String_value>,
              "filelocation":<String_value>,
              "fileencoding":<String_value>
        }}
        Response:
        HTTP Status Code on Success: 201 Created
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/systemfile"

    # Creating the right payload formatting (mind the Depth for the nested arrays)

    # Get FileName, Content and Base64 String from the FilePath, Keep in mind that the filenames are case-sensitive
    $PathToFile = $CertFolder + "\IDPCAroot.cer"
    $FileRootName = Split-Path -Path $PathToFile -Leaf                                                 # Parameter explained: -Leaf     => Indicates that this cmdlet returns only the last item or container in the path. For example, in the path C:\Test\Logs\Pass1.log, it returns only Pass1.log.
    $FileRootContent = Get-Content $PathToFile -Encoding "Byte"
    $FileRootContentBase64 = [System.Convert]::ToBase64String($FileRootContent)

    $PathToFile = $CertFolder + "\IDPcert.cer"
    $FileCertName = Split-Path -Path $PathToFile -Leaf                                                 # Parameter explained: -Leaf     => Indicates that this cmdlet returns only the last item or container in the path. For example, in the path C:\Test\Logs\Pass1.log, it returns only Pass1.log.
    $FileCertContent = Get-Content $PathToFile -Encoding "Byte"
    $FileCertContentBase64 = [System.Convert]::ToBase64String($FileCertContent)

    $payload = @{
        "systemfile"= @(
            @{"filename"=$FileRootName; "filecontent"=$FileRootContentBase64; "filelocation"="/nsconfig/ssl/"; "fileencoding"="BASE64"},
            @{"filename"=$FileCertName; "filecontent"=$FileCertContentBase64; "filelocation"="/nsconfig/ssl/"; "fileencoding"="BASE64"}
        )
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorVariable restError
#endregion Upload certificate

#region Add certificate - key pairs
    <#
        add
        URL:http://<netscaler-ip-address>/nitro/v1/config/sslcertkey
        HTTP Method:POST
        Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
        Request Payload:
        {"sslcertkey":{
              "certkey":<String_value>,
              "cert":<String_value>,
              "key":<String_value>,
              "password":<Boolean_value>,
              "fipskey":<String_value>,
              "hsmkey":<String_value>,
              "inform":<String_value>,
              "passplain":<String_value>,
              "expirymonitor":<String_value>,
              "notificationperiod":<Double_value>,
              "bundle":<String_value>
        }}
        Response:
        HTTP Status Code on Success: 201 Created
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/sslcertkey"

    # add ssl certKey RootCA -cert "/nsconfig/ssl/rootCA.cer" -inform DER -expiryMonitor ENABLED -notificationPeriod 25
    $payload = @{
        "sslcertkey"= @(
            @{"certkey"="idp_root_ca"; "cert"="/nsconfig/ssl/IDPCAroot.cer"; "inform"="PEM"; "expirymonitor"="ENABLED"; "notificationperiod"=25},
            @{"certkey"="idp_demo_lab"; "cert"="/nsconfig/ssl/IDPcert.cer"; "inform"="PEM"; "expirymonitor"="ENABLED"; "notificationperiod"=25}
        )
    } | ConvertTo-Json -Depth 5

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add certificate - key pairs

#region Add certificate - links
    <#
        link
        URL:http://<netscaler-ip-address>/nitro/v1/config/sslcertkey?action=link
        HTTP Method:POST
        Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
        Request Payload:
        {"sslcertkey":{
              "certkey":<String_value>,
              "linkcertkeyname":<String_value>
        }}
        Response:
        HTTP Status Code on Success: 200 OK
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>    
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/sslcertkey?action=link"

    # link ssl certKey wildcard.demo.lab RootCA 
    $payload = @{
    "sslcertkey"= @{
        "certkey"="idp_demo_lab";
        "linkcertkeyname"="idp_root_ca";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add certificate - links


# --------------------------
# | Add SAML Configuration |
# --------------------------
#region Add SAML Server
<#
    add

    URL:http://<netscaler-ip-address>/nitro/v1/config/authenticationsamlaction

    HTTP Method:POST

    Request Headers:

    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json

    Request Payload:

    {"authenticationsamlaction":{
          "name":<String_value>,
          "samlidpcertname":<String_value>,
          "samlsigningcertname":<String_value>,
          "samlredirecturl":<String_value>,
          "samlacsindex":<Double_value>,
          "samluserfield":<String_value>,
          "samlrejectunsignedassertion":<String_value>,
          "samlissuername":<String_value>,
          "samltwofactor":<String_value>,
          "defaultauthenticationgroup":<String_value>,
          "attribute1":<String_value>,
          "attribute2":<String_value>,
          "attribute3":<String_value>,
          "attribute4":<String_value>,
          "attribute5":<String_value>,
          "attribute6":<String_value>,
          "attribute7":<String_value>,
          "attribute8":<String_value>,
          "attribute9":<String_value>,
          "attribute10":<String_value>,
          "attribute11":<String_value>,
          "attribute12":<String_value>,
          "attribute13":<String_value>,
          "attribute14":<String_value>,
          "attribute15":<String_value>,
          "attribute16":<String_value>,
          "signaturealg":<String_value>,
          "digestmethod":<String_value>,
          "requestedauthncontext":<String_value>,
          "authnctxclassref":<String[]_value>,
          "samlbinding":<String_value>,
          "attributeconsumingserviceindex":<Double_value>,
          "sendthumbprint":<String_value>,
          "enforceusername":<String_value>,
          "logouturl":<String_value>,
          "artifactresolutionserviceurl":<String_value>,
          "skewtime":<Double_value>
    }}

    Response:

    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error

#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/authenticationsamlaction"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add authentication samlAction svr_saml_adfs -samlIdPCertName idp_root_ca -samlSigningCertName wildcard.demo.lab -samlRedirectUrl "http://idp.demo.lab/adfs/ls" -samlUserField NameID -samlIssuerName idp.demo.lab -signatureAlg RSA-SHA256 -digestMethod SHA256

    $payload = @{
    "authenticationsamlaction"= @{
          "name"="svr_saml_adfs";
          "samlidpcertname"="idp_root_ca";
          "samlsigningcertname"="wildcard.demo.lab";
          "samlredirecturl"="http://idp.demo.lab/adfs/ls";
          "samluserfield"="NameID";
          "samlrejectunsignedassertion"="ON";
          "samlissuername"="idp.demo.lab";
          "signaturealg"="RSA-SHA256";
          "digestmethod"="SHA256";
          "samlbinding"="POST";
          "enforceusername"="ON"
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add SAML Server

#region Add SAML policy
<#
    add

    URL:http://<netscaler-ip-address>/nitro/v1/config/authenticationsamlpolicy

    HTTP Method:POST

    Request Headers:

    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
    Content-Type:application/json

    Request Payload:

    {"authenticationsamlpolicy":{
            "name":<String_value>,
            "rule":<String_value>,
            "reqaction":<String_value>
    }}

    Response:

    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error

#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/authenticationsamlpolicy"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # add authentication samlPolicy pol_saml_adfs ns_true svr_saml_adfs

    $payload = @{
    "authenticationsamlpolicy"= @{
          "name"="pol_saml_adfs";
          "rule"="ns_true";
          "reqaction"="svr_saml_adfs"
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add SAML policy

#region Unbind LDAP Policy to vServer
<#
    delete:

    URL:http://<netscaler-ip-address>/nitro/v1/config/vpnvserver_authenticationsamlpolicy_binding/name_value<String>

    Query-parameters:

    args

    http://<netscaler-ip-address>/nitro/v1/config/vpnvserver_authenticationsamlpolicy_binding/name_value<String>?args=policy:<String_value>,secondary:<Boolean_value>,groupextraction:<Boolean_value>,bindpoint:<String_value>

    HTTP Method:DELETE

    Request Header:

    Cookie:NITRO_AUTH_TOKEN=<tokenvalue>

    Response:

    HTTP Status Code on Success: 200 OK
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/vpnvserver_authenticationldappolicy_binding/vsvr_nsg_demo_lab"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # bind vpn vserver vsvr_nsg_demo_lab -policy Demo_LDAP_pol -priority 100

    $args = "?args=" + "policy:pol_LDAP_dc001"
    $strURI = $strURI + $args

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Uri $strURI -Method Delete -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Unbind LDAP Policy to vServer

#region Bind SAML Policy to vServer
<#
    add:
    URL: http://<netscaler-ip-address/nitro/v1/config/vpnvserver_authenticationldappolicy_binding
    HTTP Method: PUT
    Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
    Request Payload: 
    {"vpnvserver_authenticationldappolicy_binding":{
          "name":<String_value>,
          "policy":<String_value>,
          "priority":<Double_value>,
          "secondary":<Boolean_value>,
          "groupextraction":<Boolean_value>,
          "gotopriorityexpression":<String_value>,
          "bindpoint":<String_value>
    }}

    Response:
    HTTP Status Code on Success: 201 Created
    HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
#>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/vpnvserver_authenticationldappolicy_binding"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # bind vpn vserver vsvr_nsg_demo_lab -policy Demo_LDAP_pol -priority 100

    $payload = @{
        "vpnvserver_authenticationldappolicy_binding"= @{
                "name"="vsvr_nsg_demo_lab";
                "policy"="pol_saml_adfs";
                "priority"=100;
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Uri $strURI -Method Post -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind SAML Policy to vServer


#TODO:


#region End NetScaler NITRO Session
    #Disconnect from the NetScaler VPX
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
#endregion End NetScaler NITRO Session

