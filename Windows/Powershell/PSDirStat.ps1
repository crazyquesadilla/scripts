param ($driveletter = "C")

function Get-FolderSize {
    param ($folder)
    [math]::round(((robocopy $folder C:\temp\ /L /XJ /R:0 /NP /E /BYTES /NFL /NDL /NJH /MT:64)[-4] -replace "\D+(\d+).*",'$1')/1GB,3)
    # most importantly, /L means that this only logs
}
    

try{
    $path = $("$driveletter`:\")
    if(!(Test-Path $path)){
        Write-Error "$path does not exist"; exit 1001
    }
    $children = get-childitem $("$driveletter`:\") -Depth 1 -ErrorAction Continue

    $children | Select-Object -property fullname,@{name="foldersize";expr={Get-FolderSize $_.fullname}} | Sort-Object foldersize -descending | Select-Object -first 10
    exit 0
}
catch {Write-Output "Script failed:`n",$_.Exception.Message; exit 1001}