#####################################################
#Script to Monitor docker images on a PAW host
#Author - rajeshr
#Name - docker_container_monitor.ps1
#Date - 02/18/2019
#####################################################

$docker_ps = @("social", "pa-gateway", "prism-proxy", "couchdb_init", "share-proxy", "share-platform", "prism-platform", "mongo", "share-app", "prism-app", "welcome", "neo-idviz", "neo-provision", "couchdb", "cdn3p", "wa-proxy", "bss", "glass", "user-admin", "redis", "tm1proxy", "admintool")
$logfile =  "D:\Utils\Logs\Docker_container_monitor.txt"
$start_count = "4"
$iter - "0"
echo "=================================== `n" | Out-File $logfile -Append
foreach ($ps in $docker_ps) 
{
$id = docker top $ps | Out-Null
if ($? -eq "True")
{
    echo "Container $ps working fine at $(get-date)" | Out-File $logfile -Append
    
 }
 else
 {
 echo "Container $ps crashed unexpectedly at $(get-date)" | Out-File $logfile -Append
 echo "Trying to start the Container $ps at $(get-date)" | Out-File $logfile -Append
 docker start $ps 
 do
 {
  $id = docker top $ps | Out-Null
  if ($? -eq "True") {break}
  echo "Container $ps still starting at $(get-date)" | Out-File $logfile -Append
    start-sleep 15
    $iter ++
 }
 while ($iter -le $start_count)
 send-MailMessage -to rraghavan@illumina.com -subject "PAW service $ps (docker images) was down on $env:COMPUTERNAME.illumina.com" -from $env:COMPUTERNAME@illumina.com -body "PAW service (docker image) $ps was down on the host $env:COMPUTERNAME.illumina.com and was restarted. See log D:\Utils\Logs\Docker_container_monitor.txt on the host $env:COMPUTERNAME.illumina.com. Check the status of services using the command docker ps on a powershell window. Check PAW using the URL http://$env:COMPUTERNAME.illumina.com" -smtpserver smtp.illumina.com 
 }
 }
 echo "`n"  | Out-File $logfile -Append