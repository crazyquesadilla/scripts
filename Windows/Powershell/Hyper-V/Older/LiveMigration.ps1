# Variables

$vms = Get-Content .\LiveMigration-VMs.txt # Specify path to list of import list
$cluster = "CMTCLUHOST"
$dest = "PMTHOST01"  #Destination Host

#Loop for each item in the list
foreach ($vm in $vms)
{
#Migrate VMs
Get-Cluster $cluster | Move-ClusterVirtualMachineRole -Name $vm -Node $dest
}