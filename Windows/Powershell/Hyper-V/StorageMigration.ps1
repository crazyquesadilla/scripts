# Get VM List

$VMstoMove = Get-Content .\StorageMigration-VMs.txt
$HVHost = "PMTHOST06"
$destLocation = "D:\Hyper-V\"

foreach ($V in $VMstoMove)
{
    $VM = Get-VM -ComputerName $HVHost -Name $V
    $newpath = $destLocation + $VM.Name
    write-host $VM.Name "moving to " $newpath
    Move-VMStorage -WhatIf -DestinationStoragePath $newpath -VM $VM
}