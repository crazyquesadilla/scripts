$SourceServer = "PHYAPPHOST08"
$ReplicaServer = "PHBBACKUP03"
$StartDate = "9/28/2016"
$StartTime = "00:30"
$ReplicaServerPort  = 80
$ReplicaServerAuthType = "Kerberos"
$ReplicationFrequencySec = 15*60 # 15x60 equals 900 secunds = 15 minutes.
 
$InitialReplicationDelayMinutes = 30
$InitialReplicationStartTime = $StartDate + " " + $StartTime
 
$AutoResynchronizeIntervalStart = "18:30:00"
$AutoResynchronizeIntervalEnd = "06:00:00"
 
$VMHostInfo = Get-VMHost -ComputerName $ReplicaServer
$ReplicaServerInfo = Get-VMReplicationServer -ComputerName $ReplicaServer

 
 
$VMs = Get-VM -ComputerName $SourceServer 

  foreach ($VM in $VMs)
        { 
        Write "Enabling Intitial Replication on  $($VM.VMname) from $SourceServer to $ReplicaServer at $InitialReplicationStartTime"
        Start-VMInitialReplication -ComputerName $SourceServer -VMName $VM.VMName -InitialReplicationStartTime $InitialReplicationStartTime
 }
