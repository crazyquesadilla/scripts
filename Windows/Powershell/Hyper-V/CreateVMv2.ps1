# .\CreateChildVMv2.ps1           #
# 
#  syntax: .\CreateChildVMv2.ps1 –NMName DB01 –VMFolder d:\VMs –OSDisk d:\VHD\WIN2012.vhdx –Memory 4096 –CPU 2 -Switch VM-Team -VLAN 37 -IP 10.0.2.222/24 -GW 10.0.2.1 -DNSDomain ipzhost.net -DNS1 10.6.19.10 -DNS2 10.6.19.20
Param
(
    [Parameter(Mandatory=$false,Position=0)]
    [string]$VMName,
    [string]$VMFolder = "D:\Hyper-V\Virtual Machines\", # D:\VMs
    [switch]$Child,
    [string]$OSDisk = "D:\Hyper-V\Templates\2016.VHDX" ,   # D:\VHD\WS2012a.vhdx
    [string]$Memory = 4096,   # amount of memory in mb
    [string]$CPU = 2,       # number of CPUs to allocate
    [string]$Switch = "VM-Team",    # name of virtual switch
    [string]$VLAN,    # VLAD Identifier
    [string]$IP,    # IP Address with mask (10.0.0.0/24)
    [string]$GW,    # IP Address of gateway (10.0.0.1)
    [string]$DNSDomain,    # name of DNS Domain
    [string]$DNS1,     # Primary DNS Server 
    [string]$DNS2     # Secondary DNS Server


)

$host.UI.RawUI.BackgroundColor = "Black"; Clear-Host

# Elevate
Write-Host "Checking for elevation... " -NoNewline
$CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
if (($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) -eq $false)  {
    $ArgumentList = "-noprofile -noexit -file `"{0}`" -Path `"$Path`""
    write-host " path: $Path"
    Write-Host "elevating"
    Start-Process powershell.exe -Verb RunAs -ArgumentList ($ArgumentList -f ($myinvocation.MyCommand.Definition))
    Exit
}

$Host.UI.RawUI.BackgroundColor = "Black"; Clear-Host
$Validate = $true

Write-Host "Importing Hyper-V module"
If (!(Get-Module Hyper-V)) {Import-Module Hyper-V}

If (Get-Module Hyper-V) {
    
    $Validate = $true
    Write-Host ""

    If ($Validate) {

        $InstallerServiceAccount = "Administrator"   
        $InstallerServiceAccountUsername = "Administrator"       
        $AdministratorPassword = "Server2016"

        $VMsFolder = $VMFolder
        $VMHost = "localhost"
        $CreateVM = $true

        Write-Host ""

        # Check required resources for creation exist

        # Get the VM host
        Write-Host "  VM - $VMName on $VMHost"
        If (!(Get-VMHost -ComputerName $VMHost -ErrorAction SilentlyContinue)) {
                $CreateVM = $false
                Write-Host "    Host $VMHost does not exist" -ForegroundColor Red
        }
        
        # Check resources on VM host only if the host exists
        If ($CreateVM) {
            # Get OS disk
            $OSDiskUNC = "\\" + $VMHost + "\" + $OSDisk.Replace(":","$")
            $VHDFolder = $VMsFolder + "\" + $VMName + "\Virtual Hard Disks"
            $VHDFolderUNC = "\\" + $VMHost + "\" + $VHDFolder.Replace(":","$")
            $OSVHDFormat = $OSDisk.Split(".")[$OSDisk.Split(".").Count - 1]
            If (!(Test-Path $OSDiskUNC)) {
                $CreateVM = $false
                Write-Host "    OS parent disk $OSDisk does not exist" -ForegroundColor Red
            }

             # Get pagefile disk


             # Get the VM switch
         }

         # Check resources to be created do not already exist
         If ($CreateVM) 
         {

             # Check the VM does not already exist
             If (Get-VM -Name $VMName -ComputerName $VMHost -ErrorAction SilentlyContinue) {
                 $CreateVM = $false
                 Write-Host "    VM already exists" -ForegroundColor Red
             }

             # Check the OS disk does not already exist
             If (Test-Path "$VHDFolderUNC\$VMName.$OSVHDFormat") {
                 $CreateVM = $false
                 Write-Host "    Disk $VHDFolder\$VMName.$OSVHDFormat already exists" -ForegroundColor Red
             }

             # Check the pagefile disk does not already exist
         }

         # Creation of the VM
         If ($CreateVM){
             # Create the VM
             Write-Host "    Creating VM: $VMName"
             New-VM -Name $VMName -ComputerName $VMHost -Path $VMsFolder -NoVHD -Generation 2 | Out-Null

             # Set processors
             Write-Host "    Setting processors to $CPU"
             Set-VMProcessor -VMName $VMName -ComputerName $VMHost -Count $CPU

             # Set memory
             Write-Host "    Setting memory to $Memory`MB"
             [Int64]$VMmemory = $Memory
             $VMmemory = $VMmemory * 1024 * 1024
             Set-VMMemory -VMName $VMName -ComputerName $VMHost -DynamicMemoryEnabled $false -StartupBytes $VMmemory

             # Set virtual switch
             Connect-VMNetworkAdapter -VMName $VMName –Switch $Switch

             If ($VLAN -ne $null){
                Set-VMNetworkAdapterVlan -VMName $VMName -Access -VlanId $vlan
             }

             # Set OS disk
             if($Child){
                New-VHD -ComputerName $VMHost -Path "$VHDFolder\$VMName.$OSVHDFormat" -ParentPath $OSDisk | Out-Null
             }
             else{
                Convert-VHD -Path $OSDisk -DestinationPath "$VHDFolder\$VMName.$OSVHDFormat" | Out-Null
             }
                          
             Write-Host "    Attaching disk $VHDFolder\$VMName.$OSVHDFormat to SCSI 0:0"
             Add-VMHardDiskDrive -VMName $VMName -ComputerName $VMHost -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0 -Path "$VHDFolder\$VMName.$OSVHDFormat"

             # Set boot order

             $bootdisk = Get-VMHardDiskDrive -VMName $VMName
             Set-VMFirmware -VMName $VMName -FirstBootDevice $bootdisk

             # Set pagefile disk

             # Set data disks
 
             # Mount OS disk to insert unattend files
             $Drive = $null
             While ($Drive -eq $null){
                 Write-Host "    Mounting $VHDFolder\$VMName.$OSVHDFormat"
                 $Drive = Mount-VHD -Path "$VHDFolderUNC\$VMName.$OSVHDFormat" -PassThru | Get-Disk | Get-Partition | Get-Volume | Where-Object {$_.FileSystemLabel -ne ‘System Reserved’} | select -ExpandProperty DriveLetter

                 If ($Drive -ne $null){
                     Write-Host "      $VHDFolder\$VMName.$OSVHDFormat mounted as $Drive`:"
                     $ExecutionContext.InvokeCommand.ExpandString($(Get-Content .\unattend.xml)) | Out-File "$Drive`:\unattend.xml" -Encoding ASCII
                 }

                 Write-Host "      Inserting SetupComplete.cmd"
                 If (!(Test-Path "$Drive`:\Windows\Setup\Scripts")) {New-Item -Path "$Drive`:\Windows\Setup\Scripts" -ItemType Directory | Out-Null}
                 Get-Content .\SetupComplete.cmd | Out-File "$Drive`:\Windows\Setup\Scripts\SetupComplete.cmd" -Encoding ASCII
                 Write-Host "      Inserting SetupComplete.ps1"

             }
             Write-Host "      Dismounting $VHDFolder\$VMName.$OSVHDFormat"
             Dismount-VHD -Path "$VHDFolderUNC\$VMName.$OSVHDFormat"
             
             # Set startup
             $AutoStartAction = "Nothing"   # Get-Value -Count $i -Value "AutoStart.Action"
             $AutoStartDelay = 0      # Get-Value -Count $i -Value "AutoStart.Delay"
             Write-Host "    Setting automatic start to `"$AutoStartAction`", delay $AutoStartDelay"
             Set-VM -VMName $VMName -ComputerName $VMHost -AutomaticStartAction $AutoStartAction
             Set-VM -VMName $VMName -ComputerName $VMHost -AutomaticStartDelay $AutoStartDelay

             # Start
             Start-VM -VMName $VMName -ComputerName $VMHost
         } 
 
        Write-Host ""
    }
    
} 
Else 
{
    Write-Host "Hyper-V module not available"
}
