$date = get-date -format yyyyMMdd-HHmmss
Start-Transcript -Path "PATH\ LOG_.$date.txt"

$archives = "OU=" 
$adminCounts = get-aduser -filter * -SearchBase $archives -Properties adminCount, Name, whenChanged, Description | Where-Object{$_.adminCount -eq "1"} | Sort-Object -Descending whenChanged

#List account with admin privilegies that are still up but in archived OU 
$adminCounts.name

#Set account to desactivate by changing admincount attribute by 0.
$adminCounts | % {Set-ADUser -Identity $_.SamAccountName -Replace @{adminCount = "0"}}

Stop-Transcript
