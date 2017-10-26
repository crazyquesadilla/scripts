$SourceServer = "PHYAPPHOST03"
$ReplicaServer = "PHBBACKUP03"
$StartDate = "9/26/2016"
$StartTime = "16:30"
$ReplicaServerPort  = 80
$ReplicaServerAuthType = "Kerberos"
$ReplicationFrequencySec = 15*60 # 15x60 equals 900 secunds = 15 minutes.
 
$InitialReplicationDelayMinutes = 30
$InitialReplicationStartTime = $StartDate + " " + $StartTime
 
$AutoResynchronizeIntervalStart = "18:30:00"
$AutoResynchronizeIntervalEnd = "06:00:00"
 
$VMHostInfo = Get-VMHost -ComputerName $ReplicaServer
$ReplicaServerInfo = Get-VMReplicationServer -ComputerName $ReplicaServer
$ReplicaDestPath = $ReplicaServerInfo.DefaultStorageLocation
 
 
$VMs = Get-VM -ComputerName $SourceServer  | ? { ($PSItem.ReplicationState -eq "Disabled") -AND ($PSItem.State -eq "Running")}
 
$VMsDiskSizeTotal = (($VMs | % { Get-VMHardDiskDrive -ComputerName $SourceServer -VMName $PSItem.Name | Get-VHD -ComputerName $SourceServer}) | measure -Property FileSize -Sum).Sum
$ReplicaServerDiskSizeFree = (Invoke-Command -ArgumentList $ReplicaDestPath -ScriptBlock {param($ReplicaDestPath) Get-Volume -DriveLetter $($ReplicaDestPath.Substring(0,1))} -ComputerName $ReplicaServer).SizeRemaining
 
 
 
#Check Diskspace before replication.
Write "$($VMsDiskSizeTotal/1TB) TB Selected for replication on $SourceServer. $($ReplicaServerDiskSizeFree/1TB) TB Avalible on $ReplicaServer."
if ( ($ReplicaServerDiskSizeFree) -AND ($VMsDiskSizeTotal -le $ReplicaServerDiskSizeFree) )
    {
 
    Write "Checking disk space avalible on $ReplicaServer"    
 
    foreach ($VM in $VMs)
        {
 
        Write "Enabling VM Replication on VM $($VM.Vmname)"
 
        Enable-VMReplication `
            -ComputerName $SourceServer `
            -VMName $VM.Vmname `
            -ReplicaServerName $ReplicaServer `
            -ReplicaServerPort $ReplicaServerPort `
            -AuthenticationType $ReplicaServerAuthType `
            -ReplicationFrequencySec $ReplicationFrequencySec `
            -AutoResynchronizeEnabled $true `
            -AutoResynchronizeIntervalStart $AutoResynchronizeIntervalStart `
            -AutoResynchronizeIntervalEnd $AutoResynchronizeIntervalEnd `
            -CompressionEnabled $true `
            -RecoveryHistory 0 `
            -Confirm:$false

        Write "Enabling Intitial Replication on  $($VM.VMname) from $SourceServer to $ReplicaServer at $InitialReplicationStartTime"
        Start-VMInitialReplication -ComputerName $SourceServer -VMName $VM.VMName -InitialReplicationStartTime $InitialReplicationStartTime
 
        # Debug
        #break
 
        }
    }
    else
        {
        Write "Checking disk space not avalible on $ReplicaServer . Script failed."
        }