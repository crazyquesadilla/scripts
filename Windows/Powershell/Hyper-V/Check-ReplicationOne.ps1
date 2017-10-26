$computers = Read-Host "What server?"
$to = Read-Host "Email who?"

$body = measure-vmreplication -ComputerName $computers | select name,state,health,lrepltime,@{Label='Average Replication Size (in MB)';expression={([Math]::Round(($_.averagereplicationsize/1MB),2))}},computername | sort computername,state | convertto-html -head "<style>body{font-family:sans-serif;};table, th, td{border:1px solid black;border-collapse:collapse;padding:6px;}; th{background-color:#ADADAD;}</style>" | out-string

$healthwarn='<td>Warning</td>'
$healthwarnaft='<td bgcolor=FC8B78>Warning</td>'
$healtherr='<td>Error</td>'
$healtherraft='<td bgcolor=FC8B78>Error</td>'
$healthcrit='<td>Critical</td>'
$healthcritaft='<td bgcolor=FC8B78>Critical</td>'
$body = $body -replace $healthwarn,$healthwarnaft
$body = $body -replace $healtherr,$healtherraft
$body = $body -replace $healthcrit,$healthcritaft

Send-MailMessage -to $to -from NOCZombie@imprezzio.com -subject "PMTREPLICA01 Hyper-V Replication Status" -body $body -smtpserver mailapp.imprezzio.com -bodyashtml
