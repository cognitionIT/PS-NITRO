#Collects Inventory on various kinds of VServers (LB Vservers, CS Vservers, GSLB VServers, etc
#Also Collects inventory on Certs and Certkeys that can be used for tracking your certificate inventory
Import-Module ..\NitroConfigurationFunctions\NITROConfigurationFunctions.psm1
. HelperFunctions.ps1
$nsList = "C:\scripts\netscaler\nslist.txt"
$nsSecureCreds = "c:\scripts\netscaler\nscred.txt"
#region creds
$nsuser = "nsroot"
$nscred = Read-SecureString -file $nsSecureCreds
#endregion creds
$joinedCertsOutFile = "C:\scripts\netscaler\nsinventory_certs_$(Get-MDY).csv"
$CombinedInventoryFile = "C:\scripts\netscaler\nsinventory_vservers$(Get-MDY).csv"
$netscalers = (Get-Content $nsList)
$invArr = @()
$joinedCerts = @()
foreach($ns in $netscalers){
    Write-Output "Connecting to $ns"
    try{
        $nssession = Connect-NSAppliance -NSName $ns -NSUserName $nsuser -NSPassword $nscred
    } catch{
    	# We won't be able to connect to this Netscaler .. lets Continue on. 
    	# If we had alreanate creds we could try then here once
    	continue
    }

    $nshostname = Get-NSHostName -NSSession $nssession
    $primaryStatus = (Invoke-NSNitroRestApiStat -NSSession $nssession -OperationMethod GET -ResourceType "hanode" ).hanode 
    #$primaryStatus
    if($primaryStatus.hacurmasterstate -eq 'Primary'){
        #$csvservers = ""
        #$vservers = ""
        #$crvservers = ""
        #$gslbvservers = ""
        #If we are on the primary node... get vservers
        $vservers = Get-NSLBVServer -NSSession $nssession
        try{
            $certKeys = (Invoke-NSNitroRestApi -NSSession $nssession -OperationMethod GET -ResourceType "sslcertkey").sslCertKey 
        }catch{}
        
        if($certKeys){
            $certKeys | Add-Member -MemberType NoteProperty -Name LB -Value $nshostname 
            $certKeys | Add-Member -MemberType NoteProperty -Name VSVRType -Value "CertKey"
            $certArr =@()
            #$subArr += $certKeys 
            #$certKeys | ft
            # This will get vserver or csvserver binding
            foreach($certKey in $certKeys){
                $bindings = ((Invoke-NSNitroRestApi -NSSession $nssession -OperationMethod GET -ResourceType "sslcertkey_binding" -ResourceName $($certKey.certkey)).sslcertkey_binding)
                #Is Being Used for Vservers or CSVServers 
                if($bindings.sslcertkey_sslvserver_binding){
                    #$certArr += $bindings.sslcertkey_sslvserver_binding
                    #$bindings.sslcertkey_sslvserver_binding | ft
                    foreach($item in $bindings.sslcertkey_sslvserver_binding){
                        $certArr += New-Object -TypeName psobject -Property @{certkey = $item.certkey; servername = $item.servername; servicename = ""; data= $item.data; version = $item.version; stateFlag = $item.stateflag; name = $item.servername}
                    }
                }
                #It is being used as a client certificate for Service Binding
                if($bindings.sslcertkey_service_binding){
                    foreach($item in $bindings.sslcertKey_service_binding){
                        $certArr += New-Object -TypeName psobject -Property @{certkey = $item.certkey; servername = ""; servicename = $item.servicename; data= $item.data; version = $item.version; stateFlag = $item.stateflag; name = $item.servicename}
                    }
                    #$bindings.sslcertkey_service_binding | ft
                }
            } #End foreach CertKey
            $certArr | Add-Member -MemberType NoteProperty -Name LB -Value $nshostname 
            $certArr | Add-Member -MemberType NoteProperty -Name VSVRType -Value "CertBinding"
            $joinedCerts+= Join-Object -Left $certArr -Right $certKeys -LeftJoinProperty certKey -RightJoinProperty certkey -LeftProperties certkey, name, servername, servicename, data, version, stateFlag -RightProperties cert, key, inform, signaturealg, certificatetype,serial,issuer, clientcertnotbefore, clientcertnotafter, status, subject, LB
            #certkey,cert, key,inform,signaturealg,certificatetype,serial,issuer, clientcertnotbefore, clientcertnotafter      
        } #End if certKeys 
        # For each vserver, look at totalservices, if gt 1, get servicegroup binding, else get service binding
        if($vservers){
            Write-Output "Adding VServers for $ns $($invArr.Count) $($vservers.Count)"
            $vservers | Add-Member -MemberType NoteProperty -Name LB -Value $nshostname 
            $vservers | Add-Member -MemberType NoteProperty -Name VSVRType -Value "VServer"
            $subArr += $vservers        
            Write-Output "Adding VServers for $ns $($subArr.Count) $($vservers.Count)"
        }
        try{
            $csvservers = (Invoke-NSNitroRestApi -NSSession $nssession -OperationMethod GET -ResourceType "csvserver").csvserver 
        } catch{}

        if($csvservers){
            $csvservers | Add-Member -MemberType NoteProperty -Name LB -Value $nshostname 
            $csvservers | Add-Member -MemberType NoteProperty -Name VSVRType -Value "CSVServer"
            $subArr += $csvservers
        }

        try{
            $gslbvservers = (Invoke-NSNitroRestApi -NSSession $nssession -OperationMethod GET -ResourceType "gslbvserver").gslbvserver 
        } catch{}

        if($gslbvservers){
            $gslbvservers | Add-Member -MemberType NoteProperty -Name LB -Value $nshostname 
            $gslbvservers | Add-Member -MemberType NoteProperty -Name VSVRType -Value "GSLBVserver"
            $subArr += $gslbvservers
        }

        try{
            $crvservers = (Invoke-NSNitroRestApi -NSSession $nssession -OperationMethod GET -ResourceType "crvserver").crvserver 
        } catch{}
        
        if($crvservers){
            $crvservers | Add-Member -MemberType NoteProperty -Name LB -Value $nshostname 
            $crvservers | Add-Member -MemberType NoteProperty -Name VSVRType -Value "CRVserver"
            $subArr += $crvservers 
        }
         try{
            $vpnvservers = (Invoke-NSNitroRestApi -NSSession $nssession -OperationMethod GET -ResourceType "vpnvserver").vpnvserver 
        } catch{}
        
        if($vpnvservers){
            $vpnvservers | Add-Member -MemberType NoteProperty -Name LB -Value $nshostname 
            $vpnvservers | Add-Member -MemberType NoteProperty -Name VSVRType -Value "VPNVserver"
            $subArr += $vpnvservers 
        }
        #authenticationvserver
        try{
            $authenticationvserver = (Invoke-NSNitroRestApi -NSSession $nssession -OperationMethod GET -ResourceType "authenticationvserver").authenticationvserver 
        } catch{}
        
        if($authenticationvserver){
            $authenticationvserver | Add-Member -MemberType NoteProperty -Name LB -Value $nshostname 
            $authenticationvserver | Add-Member -MemberType NoteProperty -Name VSVRType -Value "AuthenticationVServer"
            $subArr += $authenticationvserver 
        }

        
    } #End foreach LB Loop

    Disconnect-NSAppliance -NSSession $nssession
    $invArr += $subArr
} #End foreach Netscaler    
$invArr | Export-CSv -NoTypeInformation -Path $CombinedInventoryFile
$joinedCerts | Export-CSv -NoTypeInformation -Path $joinedCertsOutFile
#$invArr | ogv
