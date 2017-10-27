.\CreateChildVMv2.ps1 `
-VMName VITTest01 `
–VMFolder D:\Hyper-V\ `
–OSDisk D:\Hyper-V\Templates\2016.vhdx `
–Memory 2048 `
–CPU 2 `
-Switch "VM Team" `
-VLAN 15 `
-IP 10.6.15.241/24 `
-GW 10.6.15.1 `
-DNSDomain it.ipzo.net `
-DNS1 10.6.15.30 `
-DNS2 10.2.15.10

.\CreateChildVMv2.ps1 `
-VMName VITTest02 `
–VMFolder D:\Hyper-V\ `
–OSDisk D:\Hyper-V\Templates\2016.vhdx `
–Memory 2048 `
–CPU 2 `
-Switch "VM Team" `
-VLAN 15 `
-IP 10.6.15.242/24 `
-GW 10.6.15.1 `
-DNSDomain it.ipzo.net `
-DNS1 10.6.15.30 `
-DNS2 10.2.15.10

.\CreateChildVMv2.ps1 `
-VMName VITTest03 `
–VMFolder D:\Hyper-V\ `
–OSDisk D:\Hyper-V\Templates\2016.vhdx `
–Memory 2048 `
–CPU 2 `
-Switch "VM Team" `
-VLAN 15 `
-IP 10.6.15.243/24 `
-GW 10.6.15.1 `
-DNSDomain it.ipzo.net `
-DNS1 10.6.15.30 `
-DNS2 10.2.15.10