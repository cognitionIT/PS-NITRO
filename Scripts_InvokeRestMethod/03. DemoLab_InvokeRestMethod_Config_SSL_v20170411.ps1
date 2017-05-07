# Add the SSL configuration to the NetScaler VPX
# 20170320: !! NOTE: remember to remove the certificate files from the NetScaler before running this script => ACTION: Cleanup script needed for Hannover !!!!

#region NITRO settings
    $ContentType = "application/json"
    $SubNetIP = "192.168.0"
    $NSIP = $SubNetIP + ".2"
    # Build my own credentials variable, based on password string
    $PW = ConvertTo-SecureString "nsroot" -AsPlainText -Force
    $MyCreds = New-Object System.Management.Automation.PSCredential ("nsroot", $PW)
    $FileRoot = "C:\GitHub\PS-NITRO\Scripts_InvokeRestMethod"

    $NSUserName = "nsroot"
    $NSUserPW = "nsroot"

    $strDate = Get-Date -Format yyyyMMddHHmmss
#endregion NITRO settings

Write-Host "---------------------------------------------------------------- " -ForegroundColor Yellow
Write-Host "| Pushing the SSL configuration to NetScaler with NITRO:       | " -ForegroundColor Yellow
Write-Host "---------------------------------------------------------------- " -ForegroundColor Yellow

    #region !! Adding a presentation demo break !!
    # ********************************************
        Read-Host 'Press Enter to continue…' | Out-Null
        Write-Host
    #endregion

# ----------------------------------------
# | Method #1: Using the SessionVariable |
# ----------------------------------------
#region Start NetScaler NITRO Session
    #Connect to the NetScaler VPX Virtual Appliance
    $Login = @{"login" = @{"username"=$NSUserName;"password"=$NSUserPW;"timeout"=”900”}} | ConvertTo-Json
    $dummy = Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/login" -Body $Login -Method POST -SessionVariable NetScalerSession -ContentType $ContentType -Verbose:$VerbosePreference
#endregion Start NetScaler NITRO Session

# --------------------------------------
# | Enable required NetScaler Features |
# --------------------------------------
#region Enable NetScaler Basic & Advanced Features
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/nsfeature?action=enable"

    # Creating the right payload formatting (mind the Depth for the nested arrays)
    # enable ns feature SSL

    $payload = @{
    "nsfeature"= @{
        "feature"=@("SSL")
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Enable NetScaler Basic & Advanced Features

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

    # get the FileName, Content and Base64 String from the FilePath
    # keep in mind that the filenames are case-sensitive
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
#endregion upload certificate

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
            @{"certkey"="RootCA"; "cert"="/nsconfig/ssl/rootCA.cer"; "inform"="PEM"; "expirymonitor"="ENABLED"; "notificationperiod"=25},
            @{"certkey"="wildcard.demo.lab"; "cert"="/nsconfig/ssl/Wildcard.pfx"; "inform"="PFX"; "passplain"="password"}
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
        "certkey"="wildcard.demo.lab";
        "linkcertkeyname"="RootCA";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Post -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Add certificate - links

#region Bind Certificate to VServer
    <#
        add:
        URL:http://<netscaler-ip-address/nitro/v1/config/sslvserver_sslcertkey_binding
        HTTP Method:PUT
        Request Headers:
        Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
        Content-Type:application/json
        Request Payload:
        {
        "sslvserver_sslcertkey_binding":{
              "vservername":<String_value>,
              "certkeyname":<String_value>,
              "ca":<Boolean_value>,
              "crlcheck":<String_value>,
              "skipcaname":<Boolean_value>,
              "snicert":<Boolean_value>,
              "ocspcheck":<String_value>
        }}
        Response:
        HTTP Status Code on Success: 201 Created
        HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
    #>
    # Specifying the correct URL 
    $strURI = "http://$NSIP/nitro/v1/config/sslvserver_sslcertkey_binding"

    # bind ssl vserver vsvr_SFStore -certkeyName wildcard.demo.lab
    $payload = @{
    "sslvserver_sslcertkey_binding"= @{
        "vservername"="vsvr_SFStore";
        "certkeyname"="wildcard.demo.lab";
        }
    } | ConvertTo-Json -Depth 5

    # Logging NetScaler Instance payload formatting
    Write-Host "payload: " -ForegroundColor Yellow
    Write-Host $payload -ForegroundColor Green

    # Method #1: Making the REST API call to the NetScaler
    $response = Invoke-RestMethod -Method Put -Uri $strURI -Body $payload -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion Bind Certificate to VServer

#region End NetScaler NITRO Session

    #region BONUS: Changing the SSL vserver config to get a green status
        <#
            delete:
            URL:http://<netscaler-ip-address>/nitro/v1/config/servicegroup_lbmonitor_binding/servicegroupname_value<String>
            Query-parameters:
            args
            http://<netscaler-ip-address>/nitro/v1/config/servicegroup_lbmonitor_binding/servicegroupname_value<String>?args=port:<Integer_value>,monitor_name:<String_value>
            HTTP Method:DELETE
            Request Header:
            Cookie:NITRO_AUTH_TOKEN=<tokenvalue>
            Response:
            HTTP Status Code on Success: 200 OK
            HTTP Status Code on Failure: 4xx <string> (for general HTTP errors) or 5xx <string> (for NetScaler-specific errors). The response payload provides details of the error
        #>
        # Specifying the correct URL 
        $strURI = "http://$NSIP/nitro/v1/config/servicegroup_lbmonitor_binding/svcgrp_SFStore?args=monitor_name:lb_mon_SFStore"

        # unbind monitor to servicegroup

        # Method #1: Making the REST API call to the NetScaler
        $response = Invoke-RestMethod -Method Delete -Uri $strURI -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
    #endregion BONUS: Changing the SSL vserver config to get a green status

    #Disconnect from the NetScaler VPX Virtual Appliance
    $LogOut = @{"logout" = @{}} | ConvertTo-Json
    Invoke-RestMethod -Uri "http://$NSIP/nitro/v1/config/logout" -Body $LogOut -Method POST -ContentType $ContentType -WebSession $NetScalerSession -Verbose:$VerbosePreference
#endregion End NetScaler NITRO Session
