$servers = get-content .\getvlans-servers.txt

foreach ($server in $servers)

 {

Get-VMNetworkAdapterVlan -ComputerName $server | ? {$_.AccessVlanId -ge "1999"}

}