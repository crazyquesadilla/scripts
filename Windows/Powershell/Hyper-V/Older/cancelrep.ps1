
#$SourceServers = Get-Content .\servers.txt
$SourceServer = "PHYAPPHOST07"

#foreach ($SourceServer in $SourceServers)
#    {
     Get-VM -computername $SourceServer | Stop-VMInitialReplication
#     }