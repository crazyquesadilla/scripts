$servers = get-content .\getvlans-servers.txt

$vms = Get-VM -ComputerName $servers

foreach ($vm in $vms)

 {

(Get-VMNetworkAdapter -VMName $vm).IpAddresses 

}