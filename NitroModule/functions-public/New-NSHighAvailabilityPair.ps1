    # New-NSHighAvailabilityPair is part of the Citrix NITRO Module
    function New-NSHighAvailabilityPair {
        <#
        .SYNOPSIS
            Configures a new high availability pair
        .DESCRIPTION
            Configures a new high availability pair
            This also means that the configuration on the primary node is propagated and synchronized with the secondary node
        .PARAMETER PrimaryNSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER SecondaryNSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER SaveAfterSync
            Specify to save the NetScaler appliance configuration (including the HA changes) after creating and synchronizing the HA pair
        .PARAMETER InitialSyncTimeout
            Time in seconds to wait for synchronization to occur until timing out. This only applies when specifying SaveAfterSync
        .PARAMETER PeerNodeId
            Node ID to use for the peer node. This is normally kept as 1
        .EXAMPLE
            New-NSHighAvailabilityPair -PrimaryNSSession $PrimarySession -SecondaryNSSession $SecondarySession
        .NOTES
            Copyright (c) Citrix Systems, Inc. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$PrimaryNSSession,
            [Parameter(Mandatory=$true)] [PSObject]$SecondaryNSSession,
            [Parameter(Mandatory=$false)] [switch]$SaveAfterSync,
            [Parameter(Mandatory=$false)] [int]$InitialSyncTimeout=900,
            [Parameter(Mandatory=$false)] [int]$PeerNodeId=1
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"
    
        #GETTING MANAGEMENT ADDRESS
        Write-Verbose "Getting management IP address from '$($PrimaryNSSession.Endpoint)'"
        $response = Invoke-NSNitroRestApi -NSSession $PrimaryNSSession -OperationMethod GET -ResourceType nsconfig
        $primaryNSIP = $response.nsconfig.ipaddress

        Write-Verbose "Getting management IP address from '$($SecondaryNSSession.Endpoint)'"
        $response = Invoke-NSNitroRestApi -NSSession $SecondaryNSSession -OperationMethod GET -ResourceType nsconfig
        $secondaryNSIP = $response.nsconfig.ipaddress
    
        #FORCE THE NODES TO PRIMARY AND SECONDARY
        Write-Verbose "Setting '$($PrimaryNSSession.Endpoint)' to STAYPRIMARY"
        $payload = @{id=0;hastatus="STAYPRIMARY"}
        $response = Invoke-NSNitroRestApi -NSSession $PrimaryNSSession -OperationMethod PUT -ResourceType hanode -Payload $payload -Action update
        Write-Verbose "Setting '$($SecondaryNSSession.Endpoint)' to STAYSECONDARY"
        $payload = @{id=0;hastatus="STAYSECONDARY"}
        $response = Invoke-NSNitroRestApi -NSSession $SecondaryNSSession -OperationMethod PUT -ResourceType hanode -Payload $payload -Action update

        #ADD ALL OTHER NODES ON EACH NETSCALER 
        Write-Verbose "Adding node $PeerNodeId for '$($SecondaryNSSession.Endpoint)' on '$($PrimaryNSSession.Endpoint)'"
        $payload = @{id=$PeerNodeId;ipaddress=$secondaryNSIP}
        $response = Invoke-NSNitroRestApi -NSSession $PrimaryNSSession -OperationMethod POST -ResourceType hanode -Payload $payload -Action add
        Write-Verbose "Adding node $PeerNodeId for '$($PrimaryNSSession.Endpoint)' on '$($SecondaryNSSession.Endpoint)'"
        $payload = @{id=$PeerNodeId;ipaddress=$primaryNSIP}
        $response = Invoke-NSNitroRestApi -NSSession $SecondaryNSSession -OperationMethod POST -ResourceType hanode -Payload $payload -Action add

        #ENABLE NODES, FIRST ON SECONDARY AND FINALLY ON PRIMARY
        Write-Verbose "Setting '$($SecondaryNSSession.Endpoint)' to ENABLED"
        $payload = @{id=0;hastatus="ENABLED"}
        $response = Invoke-NSNitroRestApi -NSSession $SecondaryNSSession -OperationMethod PUT -ResourceType hanode -Payload $payload -Action update
        Write-Verbose "Setting '$($PrimaryNSSession.Endpoint)' to ENABLED"
        $payload = @{id=0;hastatus="ENABLED"}
        $response = Invoke-NSNitroRestApi -NSSession $PrimaryNSSession -OperationMethod PUT -ResourceType hanode -Payload $payload -Action update
    

        if ($SaveAfterSync) {
            $canWait = $true
            $waitStart = Get-Date
            while ($canWait) {
                Write-Verbose "Waiting for synchronization to complete..."
                Start-Sleep -Seconds 5
                $validation = Invoke-NSNitroRestApi -NSSession $PrimaryNSSession -OperationMethod GET -ResourceType hanode
                $secondaryNode = $validation.hanode | where { $_.id -eq "$PeerNodeId" }
                if ($($(Get-Date) - $waitStart).TotalSeconds -gt $InitialSyncTimeout) {
                    $canWait = $false
                } elseif ($secondaryNode.hasync -eq "IN PROGRESS" -or $secondaryNode.hasync -eq "ENABLED") {
                    Write-Verbose "Synchronization not done yet."
                    continue
                } elseif ($secondaryNode.hasync -eq "SUCCESS") {
                    Write-Verbose "Synchronization succesful. Saving configuration on both NetScaler appliances..."
                    Save-NSConfig -NSSession $PrimaryNSSession
                    Save-NSConfig -NSSession $SecondaryNSSession
                    break
                } else {
                    throw "Unexpected sync status '$($secondaryNode.hasync)'"
                }
            }

            if (-not $canWait) {
                throw "Timeout expired. Unable to save NetScaler appliance configuration because sync took too long."
            }
        }

        Write-Verbose "$($MyInvocation.MyCommand): Exit"

    }
