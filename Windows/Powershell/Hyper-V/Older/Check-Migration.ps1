# $computers = Read-Host "What server?"
#$to = Read-Host "Email who?"

$body = Get-WmiObject -ComputerName PMTHOST05 -Namespace root\virtualization\v2 -Class Msvm_MigrationJob | ft PercentComplete | out-string



Send-MailMessage -to kylec@imprezzio.com -from NOCZombie@imprezzio.com -subject "Migration Status" -body $body -smtpserver mailapp.imprezzio.com -bodyashtml
