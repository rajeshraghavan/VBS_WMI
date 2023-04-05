try
{
$Error.Clear()
$destination="E:\Logs"
$logfile="$destination\IDQBounce.txt"
$recipients = @("ILMN-Role-Informatica-Admin@illumina.com", "asangale@illumina.com", "odovalina@illumina.com")

D:\Informatica\10.2.0\tomcat\bin\infaservice.bat shutdown | Out-File $logfile -Append

sleep -s 120

Get-Process java -IncludeUserName | Out-File $logfile -Append

}
catch
{
Send-MailMessage -to rraghavan@illumina.com -subject "Error occured during IDQ bounce on $env:COMPUTERNAME" -from $env:COMPUTERNAME@illumina.com -Priority High -body "Error occured: IDQ service could not stop. Error message is $Error" -smtpserver smtp.illumina.com

}

Restart-Computer -Force

