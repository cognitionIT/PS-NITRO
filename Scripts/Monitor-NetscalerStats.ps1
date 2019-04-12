#Get stats for Netscaler LB VServers and publish to InfluxDB so that we can use the time series
#I intend to integrate this into Grafana
Import-Module ..\NitroConfigurationFunctions\NITROConfigurationFunctions.psm1
$nsuser = "nsroot"
$nscred = 'passwordhere'
$netscalerList = "c:\scripts\netscaler\nslist.txt
$netscalers = Get-Content $netscalerList
$uri = "https://influxdb.domain.com/write?db=netscalerstats"
$domainSuffix = "domain.com"
$lbSuffix1 = "-lb1"
$lbSuffix2 = "-lb2"
#$x | select -Property name, vslbhealth, totalrequestbytes, totalresponsebytes, totalpktsrecvd, totalpktssent, tothits, requestsrate, pktssentrate, totvserverdownbackuphits, totspillovers, curclntconnections, cursrvrconnections, curmptcpsessions, cursubflowconn 
While($true){
    foreach($ns in $netscalers){
    Write-Output "Connecting to $ns $(Get-Date)"
    $nssession = Connect-NSAppliance -NSName $ns -NSUserName $nsuser -NSPassword $nscred -ErrorAction Continue
    $nshostname = Get-NSHostName -NSSession $nssession
    $primaryStatus = (Invoke-NSNitroRestApiStat -NSSession $nssession -OperationMethod GET -ResourceType "hanode" ).hanode 
    if($primaryStatus.hacurmasterstate -eq 'Primary'){
    	#Remove Suffix for each HA instance.. so that metric name does not change as we fail over between instances
        $nsGeneralName = $ns -replace $lbSuffix1,'' -replace $lbSuffix2,'' -replace $domainSuffix,''
        #If we are on the primary node... get vservers
        $vservers = (Invoke-NSNitroRestApiStat -NSSession $nssession -OperationMethod GET -ResourceType lbvserver).lbvserver
        $postData = ""
        foreach($vserver in $vservers){
            $Entity = "$($nsGeneralName)_$($vserver.name)" -replace " ","_"
            $hash = @{
                VSV_HealthPercent = $vserver.vslbhealth
                VSV_ClientConn = $vserver.curclntconnections
                VSV_BackendConn = $vserver.cursrvrconnections
                VSV_requestsrate = $vserver.requestsrate 
                VSV_responsesrate = $vserver.responsesrate
                VSVR_tothits = $vserver.tothits
                VSV_totvserverdownbackuphits = $vserver.totvserverdownbackuphits
                VSV_totspillovers = $vserver.totspillovers
            }
            #post the metrics we put into the hash as separate measurements in InfluxDB
            foreach($key in $hash.keys){
                $postData += "$key,LB=$nsGeneralName,VServer=$($vserver.name -replace " ","_") value=$($hash["$key"])`n" 
            }      
        }
        #In case you want to see what is being posted
        #$postData
        Invoke-RestMethod -Method Post -UseBasicParsing -Uri $uri -Body $postData

        <#$vservers.lbvserver | where {$_.state -eq 'UP'} | select -Property name, vslbhealth, curclntconnections, cursrvrconnections, curmptcpsessions, `
          totalrequestbytes, totalresponsebytes, totalpktsrecvd, totalpktssent, tothits, `
          requestsrate, pktssentrate, totvserverdownbackuphits, totspillovers, cursubflowconn | ft #>
    }
    Disconnect-NSAppliance -NSSession $nssession
}
	#Sleep 30 seconds before starting the cycle again
    start-sleep 30
}

<#
Here are some properties you can track
name                            : VSERVER-TEST-1
sortorder                       : descending
avgcltttlb                      : 0
cltresponsetimeapdex            : 1.000000
vsvrsurgecount                  : 0
establishedconn                 : 0
inactsvcs                       : 0
vslbhealth                      : 100
primaryipaddress                : 10.0.0.2
primaryport                     : 80
type                            : HTTP
state                           : UP
actsvcs                         : 1
tothits                         : 100
hitsrate                        : 0
totalrequests                   : 100
requestsrate                    : 0
totalresponses                  : 100
responsesrate                   : 0
totalrequestbytes               : 111572
requestbytesrate                : 0
totalresponsebytes              : 616776
responsebytesrate               : 0
totalpktsrecvd                  : 2446
pktsrecvdrate                   : 0
totalpktssent                   : 1779
pktssentrate                    : 0
curclntconnections              : 0
cursrvrconnections              : 0
curpersistencesessions          : 0
curbackuppersistencesessions    : 0
surgecount                      : 0
svcsurgecount                   : 0
sothreshold                     : 0
totspillovers                   : 0
labelledconn                    : 0
pushlabel                       : 0
deferredreq                     : 0
deferredreqrate                 : 0
invalidrequestresponse          : 0
invalidrequestresponsedropped   : 0
totvserverdownbackuphits        : 0
curmptcpsessions                : 0
cursubflowconn                  : 0
totcltttlbtransactions          : 98
cltttlbtransactionsrate         : 0
toleratingttlbtransactions      : 8
toleratingttlbtransactionsrate  : 0
frustratingttlbtransactions     : 5
frustratingttlbtransactionsrate : 0
#>
