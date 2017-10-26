$List = Get-Content .\List.txt

foreach ($L in $List)
{
    md -Path .\$L

}