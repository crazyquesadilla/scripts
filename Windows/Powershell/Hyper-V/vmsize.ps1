$SourceServers = Get-Content .\servers.txt
#$SourceServer = "PHYAPPHOST08"

foreach ($SourceServer in $SourceServers)
     {

$VMs = Get-VM -ComputerName $SourceServer
$VMsDiskSizeTotal = (($VMs | % { Get-VMHardDiskDrive -ComputerName $SourceServer -VMName $PSItem.Name | Get-VHD -ComputerName $SourceServer}) | measure -Property FileSize -Sum).Sum

Write "$($VMsDiskSizeTotal/1TB) TB Selected for replication from $SourceServer"

}