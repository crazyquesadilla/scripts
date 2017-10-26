$NewVMs = Get-Content .\NewVMs.txt
$TemplatePath = 'C:\ClusterStorage\Volume1\Templates\TemplateVM\Virtual Machines\EA05766E-9BC7-4A9B-822B-290E44B6F1AD.XML'


foreach ($NewVM in $NewVMs)
{
  
$Path =  'C:\ClusterStorage\Volume2\' + $NewVM
$VHDPath = $Path + '\Virtual Hard Disks\'

Import-VM -Path $TemplatePath -Copy -GenerateNewId -VhdDestinationPath $VHDPath -VirtualMachinePath $Path -SnapshotFilePath $Path -SmartPagingFilePath $Path

Rename-VM TemplateVM -NewName $NewVM

}