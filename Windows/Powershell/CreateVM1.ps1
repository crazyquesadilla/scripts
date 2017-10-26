# CreateVM.ps1           #
# 
#  syntax: .\CreateVM –NMName DB01 –VMFolder d:\VMs –OSDisk d:\VHD\WIN2012.vhdx –Memory 4096 –CPU 2 -Switch VM-Team
Param
(
    [Parameter(Mandatory=$false,Position=0)]
    [string]$VMName,
    [string]$VMFolder, # D:\VMs
    [string]$OSDisk,   # D:\VHD\WS2012a.vhdx
    [string]$Memory,   # amount of memory in mb
    [string]$CPU,       # number of CPUs to allocate
    [string]$Switch    # name of virtual switch
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

# Check PS host
If ($Host.Name -ne 'ConsoleHost') {
    $Validate = $false
    Write-Host "CreateVM.ps1 should not be run from ISE" -ForegroundColor Red
}


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
         If ($CreateVM) 
         {
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


             # Set OS disk
             Convert-VHD -Path $OSDisk -DestinationPath "$VHDFolder\$VMName.$OSVHDFormat"
             
             Write-Host "    Attaching disk $VHDFolder\$VMName.$OSVHDFormat to SCSI 0:0"
             Add-VMHardDiskDrive -VMName $VMName -ComputerName $VMHost -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0 -Path "$VHDFolder\$VMName.$OSVHDFormat"

             # Set boot order

             $bootdisk = Get-VMHardDiskDrive -VMName $VMName
             Set-VMFirmware -VMName $VMName -FirstBootDevice $bootdisk

             # Set pagefile disk

             # Set data disks
 
             # Mount OS disk to insert unattend files
             $Drive = $null
             While ($Drive -eq $null) 
             {
                 Write-Host "    Mounting $VHDFolder\$VMName.$OSVHDFormat"
                 $Drive = Mount-VHD -Path "$VHDFolderUNC\$VMName.$OSVHDFormat" -PassThru | Get-Disk | Get-Partition | Get-Volume | Where-Object {$_.FileSystemLabel -ne ‘System Reserved’} | select -ExpandProperty DriveLetter

                 If ($Drive -ne $null) 
                 {

                     Write-Host "      $VHDFolder\$VMName.$OSVHDFormat mounted as $Drive`:"

@"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>$VMName</ComputerName>
            <RegisteredOrganization></RegisteredOrganization>
            <RegisteredOwner></RegisteredOwner>
        </component>
"@ | Out-File "$Drive`:\unattend.xml" -Encoding ASCII
                 }


@"
        <component name="Networking-MPSSVC-Svc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <DomainProfile_EnableFirewall>false</DomainProfile_EnableFirewall>
            <PrivateProfile_EnableFirewall>false</PrivateProfile_EnableFirewall>
            <PublicProfile_EnableFirewall>false</PublicProfile_EnableFirewall>
        </component>
        <component name="Microsoft-Windows-TerminalServices-LocalSessionManager" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <fDenyTSConnections>false</fDenyTSConnections>
        </component>
        <component name="Microsoft-Windows-TerminalServices-RDP-WinStationExtensions" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <UserAuthentication>0</UserAuthentication>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <UserAccounts>
                <AdministratorPassword>
                    <Value>$AdministratorPassword</Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
            </UserAccounts>
            <RegisteredOrganization></RegisteredOrganization>
            <RegisteredOwner></RegisteredOwner>
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <SkipMachineOOBE>true</SkipMachineOOBE>
            </OOBE>
        </component>
    </settings>
</unattend>
"@ | Out-File "$Drive`:\unattend.xml" -Append -Encoding ASCII
                 Write-Host "      Inserting SetupComplete.cmd"
                 If (!(Test-Path "$Drive`:\Windows\Setup\Scripts")) {New-Item -Path "$Drive`:\Windows\Setup\Scripts" -ItemType Directory | Out-Null}
@"
@echo off
if exist %SystemDrive%\unattend.xml del %SystemDrive%\unattend.xml
reg add HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell /v ExecutionPolicy /t REG_SZ /d "Unrestricted" /f
powershell.exe -command %WinDir%\Setup\Scripts\SetupComplete.ps1
"@ | Out-File "$Drive`:\Windows\Setup\Scripts\SetupComplete.cmd" -Encoding ASCII

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