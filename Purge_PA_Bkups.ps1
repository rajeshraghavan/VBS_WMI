##################################################
#Script to delete PA backups older than 30 days
#Author - rajeshr
# Date - 10/18/2018
##################################################
function Purge_OlderThan()
{
PARAM(
[Parameter(ValueFromPipeline=$true)][Object[]]$Folder
)
echo "$(Get-TimeStamp): Files that will be deleted are " | Out-File $logfile -Append
Get-ChildItem -Path $Folder -Filter *.zip | ? {$_.LastWriteTime -lt $limit} | Out-File $logfile -Append
Get-ChildItem -Path $Folder -Filter *.zip | ? {$_.LastWriteTime -lt $limit} | Remove-Item -Force
echo "********************************************************" | Out-File $logfile -Append
}

function Get-TimeStamp 
{
 return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

###########
#Main
###########

$destination="D:\Utils\Logs"
$logfile="$destination\PA_Purge.txt"
$limit = (Get-Date).AddDays(-90)

Purge_OlderThan "\\ussd-file\Company\Apps\cognos\Backups\PlanningAnalytics\TST\Sales"
Purge_OlderThan "\\ussd-file\Company\Apps\cognos\Backups\PlanningAnalytics\TST\Finance"
Purge_OlderThan "\\ussd-file\Company\Apps\cognos\Backups\PlanningAnalytics\TST\Finance_Ops"
#Purge_OlderThan "D:\Temp2"


#$path_sls="\\ussd-file\Company\Apps\cognos\Backups\PlanningAnalytics\DEV\Sales"
#$path_fin="\\ussd-file\Company\Apps\cognos\Backups\PlanningAnalytics\DEV\Finance"

# Delete files older than the $limit.
#Get-ChildItem -Path $path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt $limit } | Remove-Item -Force

#echo "Files that will be deleted are: " | Out-File $logfile -Append

#Get-ChildItem -Path $path_sls -Filter *.zip | Out-File $logfile -Append

#Get-ChildItem -Path $path_sls -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } |Remove-Item -Force 
#Get-ChildItem -Path $path_sls -Filter *.zip | ? {$_.LastWriteTime -lt $limit} | Remove-Item -Force

# Delete any empty directories left behind after deleting the old files.
#Get-ChildItem -Path $path -Recurse -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse