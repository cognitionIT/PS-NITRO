#Collects VServers, Services, Service Groups and Certs and de-normalizes/flattens out the VIP structure into a CSV Format
#Only looks at LB Vservers and not csvservers, etc also returns only the name of the certkey binding, no additional detail
#It seems to not export information on some VServers and that is yet to be debugged
Import-Module ..\NitroConfigurationFunctions\NITROConfigurationFunctions.psm1
. HelperFunctions.ps1
$outfile = "c:\output\nsinventory_$(Get-MDY).csv
#region creds
$nsuser = "nsroot"
# Assuming you saved it with the available helper function Save-SecureString -file <path> 
# and running with same account on same machine. Otherwise embed password in clear
$nscred = Read-SecureString -file C:\scripts\netscaler\nscred.txt
#endregion creds

$netscalers = (Get-Content C:\scripts\netscaler\nslist.txt)
$invArr = @()
foreach($ns in $netscalers){
    Write-Output "Connecting to $ns"
    try{
        $nssession = Connect-NSAppliance -NSName $ns -NSUserName $nsuser -NSPassword $nscred
    } catch{
    	Write-Error "Failed to connect to $ns"
        continue
    }

    $nshostname = Get-NSHostName -NSSession $nssession
    $primaryStatus = (Invoke-NSNitroRestApiStat -NSSession $nssession -OperationMethod GET -ResourceType "hanode" ).hanode 
    #$primaryStatus
    if($primaryStatus.hacurmasterstate -eq 'Primary'){
        #If we are on the primary node... get vservers
        $vservers = Get-NSLBVServer -NSSession $nssession
        #For each vserver, look at totalservices, if gt 1, get servicegroup binding, else get service binding
        foreach($vserver in $vservers){
            Write-Debug "Running foreach VServer"
            $svg=""
            $sv=""
            $vserverCert=""
            $servers=""
            Write-Debug "Running Get Key Binding"
            $vserverCert = Get-NSSSLVServerCertKeyBinding -NSSession $nssession -VServerName $vserver.name -ErrorAction SilentlyContinue 
            # $vserverCert | select -Property vservername, certkeyname | ft
            #If there is more than one in the chain, let's just take the first
            if(($vserverCert.Count) -gt 1){$vserverCert = $vserverCert[0]}
                                                                                                                                                                        if($vserver.totalservices -gt 1){
            $svgArr = @()
            Write-Debug "Getting vServer to Service Group Binding for $($vserver.name)"
            $svg = Get-NSLBVServerServiceGroupBinding -NSSession $nssession -Name $vserver.name
            #$svg
            if($svg){
                $servers = Get-NSServicegroupServicegroupmemberBinding -NSSession $nssession -Name $svg.servicegroupname
                foreach($server in $servers){
                $tempHash = [ordered]@{
                    NSHost = $nshostname
                    vServerName = $vserver.name
                    vserverVIP = $vserver.ipv46
                    vServerPort = $vserver.port
                    vServerType = $vserver.servicetype
                    vServerServices = $vserver.totalservices
                    vServerEffState = $vserver.effectivestate
                    vServerCurrState = $vserver.curstate
                    vServerHealth = $vserver.health
                    vServerPersistenceType = $vserver.persistencetype
                    vServerLBMethod = $vserver.lbmethod
                    vServerConnFailover = $vserver.connfailover
                    vServerBindSvcIP = $vserver.vsvrbindsvcip
                    vServerCert = if($vserverCert){$vserverCert.certkeyname}else{$null}
                    vServerGSLBEnabled = $vserver.isgslb
                    ServiceName = $svg.servicegroupname
                    Servicegroupname = $svg.servicegroupname
                    ServiceType = $svg.servicetype
                    servicegroupeffectivestate = $svg.servicegroupeffectivestate
                    ServiceServerIP = $server.ip
                    ServiceServer = $server.servername
                    ServiceServerPort = $server.port
                    ServiceServerSvrState = $server.svrstate
                    ServiceServerStateChangeTime = $server.statechangetimesec
                    ServiceServerState = $server.state
                }
                $invArr += New-Object -TypeName PSObject -Property $tempHash

            }
            }
            
                                                                                                                                                            }else{
            Write-Debug "Getting Service binding information for $($vserver.name) "
            $svBinding = Get-NSLBVServerServiceBinding -NSSession $nssession -Name $vserver.name
            # ($svBinding).Count
            # $svBinding | ft
            if($svBinding.servicename){
                Write-Debug "Getting Service  information for $($vserver.name) $($svBinding.servicename)"
                $sv = Get-NSService -NSSession $nssession -Name $svBinding.servicename
                $tempHash = [ordered]@{
                NSHost = $nshostname
                vServerName = $vserver.name
                vserverVIP = $vserver.ipv46
                vServerPort = $vserver.policysubtype
                vServerType = $vserver.servicetype
                vServerServices = $vserver.totalservices
                vServerEffState = $vserver.effectivestate
                vServerCurrState = $vserver.curstate
                vServerHealth = $vserver.health
                vServerPersistenceType = $vserver.persistencetype
                vServerLBMethod = $vserver.lbmethod
                vServerConnFailover = $vserver.connfailover
                vServerBindSvcIP = $vserver.vsvrbindsvcip
                vServerCert = if($vserverCert){$vserverCert.certkeyname}else{$null}
                vServerGSLBEnabled = $vserver.isgslb
                ServiceName = $sv.name
                Servicegroupname = $null
                ServiceType = $sv.servicetype
                servicegroupeffectivestate = $svBinding.curstate
                ServiceServerIP = $sv.ipaddress
                ServiceServer = $sv.servername
                ServiceServerPort = $sv.port
                ServiceServerSvrState = $sv.svrstate
                ServiceServerStateChangeTime = $sv.statechangetimesec
                ServiceServerState = $sv.svrstate
            }
                $invArr += New-Object -TypeName PSObject -Property $tempHash
            }
        }
        
    } #End foreach VServer
    } #End if
    Disconnect-NSAppliance -NSSession $nssession
} #end each Appliance
#$invArr | ogv
$invArr | Export-CSV -NoTypeInformation -path $outFile -NoClobber 
