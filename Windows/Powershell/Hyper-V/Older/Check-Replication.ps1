$computers = Get-Content .\Check-Replication-Hosts.txt

$measure = measure-vmreplication -ComputerName $computers

$critical = $measure | where {$_.State -ne "Replicating" -and $_.Health -ne "Normal"}
$normal = $measure | where {$_.State -eq "Replicating" -or $_.Health -eq "Normal"}

if($critical -ne $null){$criticalhtml = $critical | select name,state,health,lrepltime,@{Label='Average Replication Size (in MB)';expression={([Math]::Round(($_.averagereplicationsize/1MB),2))}},computername | sort computername | ConvertTo-Html -PreContent "<h2>Critical</h2>" -PostContent "<br/>" -fragment}
if($normal){$normalhtml = $normal | select name,state,health,lrepltime,@{Label='Average Replication Size (in MB)';expression={([Math]::Round(($_.averagereplicationsize/1MB),2))}},computername | sort computername | ConvertTo-Html -PreContent "<h2>Healthy</h2>" -PostContent "<br/>" -fragment}

$head = "<style>body{font-family:sans-serif;};h1{font-family:sans-serif;margin-bottom:3px};table, th, td{border:1px solid black;border-collapse:collapse;padding:6px;}; th{background-color:#ADADAD;}</style>"

$body = $head + $criticalhtml + $normalhtml
#$body = measure-vmreplication -ComputerName $computers | select name,state,health,lrepltime,@{Label='Average Replication Size (in MB)';expression={([Math]::Round(($_.averagereplicationsize/1MB),2))}},computername | sort computername,state | convertto-html -head "<style>body{font-family:sans-serif;};table, th, td{border:1px solid black;border-collapse:collapse;padding:6px;}; th{background-color:#ADADAD;}</style>" | out-string

$healthwarn='<td>Warning</td>'
$healthwarnaft='<td bgcolor=FC8B78>Warning</td>'
$healtherr='<td>Error</td>'
$healtherraft='<td bgcolor=FC8B78>Error</td>'
$healthcrit='<td>Critical</td>'
$healthcritaft='<td bgcolor=FC8B78>Critical</td>'
$body = $body -replace $healthwarn,$healthwarnaft
$body = $body -replace $healtherr,$healtherraft
$body = $body -replace $healthcrit,$healthcritaft

Send-MailMessage -to noc@imprezzio.com,kevinl@imprezzio.com,kylec@imprezzio.com -from NOCZombie@imprezzio.com -subject "PMTREPLICA01 Hyper-V Replication Status" -body $body -smtpserver mailapp.imprezzio.com -bodyashtml
