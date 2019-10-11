function Get-FolderSize {
    param ($folder)
    [math]::round(((robocopy $folder C:\temp\ /L /XJ /R:0 /NP /E /BYTES /NFL /NDL /NJH /MT:64)[-4] -replace "\D+(\d+).*",'$1')/1GB,3)
}
    
 
$children = get-childitem C:\ -Depth 1 -ErrorAction SilentlyContinue 
$children | Select-Object -property fullname,@{name="foldersize";expr={Get-FolderSize $_.fullname}} | Sort-Object foldersize -descending | Select-Object -first 10
