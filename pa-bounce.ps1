<#
Name: Tm1_bounce.ps1
Description: Script to Start/Stop TM1 instances
Usage: powershell.exe <path>\Tm1_bounce.ps1
Author: rraghavan
Date: 01-29-2018
#>

Function ServiceStop()
{
[CmdletBinding()]Param(
[Parameter(Mandatory=$true)]
[string]$ServiceName
)
if(((Get-Service -Name $ServiceName).status -eq 'stopped')){Write-Host "$ServiceName service is already in stopped status"}
else
{
    Write-Host "stopping $ServiceName service"
    "$(get-date): Stopping $ServiceName service at $(get-date)" | Out-File $logfile -Append
    Get-Service -Name $ServiceName | Stop-Service -Force > $null
    do
    {
        if(((Get-Service -Name $ServiceName).status -eq 'stopped')){break}
        Write-Host "service is still stopping" -ForegroundColor Green
        Start-Sleep -Seconds 10
    }while(((Get-Service -Name $ServiceName).status -eq 'running') -or ((Get-Service -Name $ServiceName).status -eq 'stopping'))
    Write-Host "$ServiceName service stopped"
    "$(get-date): $ServiceName service stopped at $(get-date)" | Out-File $logfile -Append
}
}

Function ServiceStart()
{[CmdletBinding()]Param(
[Parameter(Mandatory=$true)]
[string]$ServiceName
)
Write-Host 'starting $ServiceName service'
"$(get-date): Starting $ServiceName service at $(get-date)" | Out-File $logfile -Append
 Get-Service -Name $ServiceName |Set-Service -Status Running > $null
$svc=get-Service -Name $ServiceName
$svc.WaitForStatus('Running', '00:02:00')
if((Get-Service $ServiceName).Status -eq 'Running')
{
Write-Host "$ServiceName service started and is running"
"$ServiceName service started at $(get-date)" | Out-File $logfile -Append
}
else
{
Send-MailMessage -to ILMN-Role-Cognos-Administrators@company.com -subject "$ServiceName service did not start up even after 2 minutes post databackup" -from $env:COMPUTERNAME@company.com -Priority High -body "$ServiceName service did not start up post Weekly bounce" -smtpserver smtp.company.com
}
}

Function RenameFile( [string] $fileName)
{

# Check the file exists
if (-not(Test-Path $fileName)) {break}

# Display the original name
"Original filename: $fileName" | Out-File $logfile -Append

$fileObj = get-item $fileName

# Get the date
$DateStamp = get-date -uformat "%Y-%m-%d_%H-%M-%S"

$extOnly = $fileObj.extension

if ($extOnly.length -eq 0) {
   $nameOnly = $fileObj.Name
   rename-item "$fileObj" "$nameOnly-$DateStamp"
   }
else {
   $nameOnly = $fileObj.Name.Replace( $fileObj.Extension,'')
   rename-item "$fileName" "$nameOnly-$DateStamp$extOnly"
   }
   
# Display the new name
"New filename: $nameOnly-$DateStamp$extOnly" | Out-File $logfile -Append
}

Function check_string( [string] $LogName, [string] $instance_name)
{
Do
{
$SEL = Select-String -Path $LogName -Pattern "ready"

if ($SEL -ne $null)
{
    echo "$(get-date): TM1 server $instance_name started successfully" | Out-File $logfile -Append
    $exit_status = 0
    Send-MailMessage -to $recipients -subject "Tm1 instance $instance_name Started successfully" -from "$env:COMPUTERNAME@company.com" -Priority Low -body "Tm1 instance $instance_name started sucessfully" -smtpserver smtp.company.com
}
else
{
    echo "$(get-date): TM1 Server $instance_name not started as per tm1server.log will check in next 180 seconds...." | Out-File $logfile -Append
    Start-Sleep -s 180
    $exit_status = 1
}
}
until($exit_status -eq 0)
}

###########
##Main
###########

try
{
$Error.Clear()
$destination="D:\Utils\Logs"
$logfile="$destination\TM1Bounce.txt"
$instance1 = "nipt"
$instance2 = "sales"
$instance3 = "finance"
$instance4 = "finance_ops"
$instance5 = "sbc"
$recipients = @("recipient1@company.com", "recipient2@company.com")
#Send-MailMessage -to $recipients -subject "Test: Ignore" -from $env:COMPUTERNAME@company.com -Priority Low -body "Test Please ignore" -smtpserver smtp.company.com

ServiceStop $instance1
Start-Sleep -s 30
ServiceStop $instance2
Start-Sleep -s 30
ServiceStop $instance3
Start-Sleep -s 30
ServiceStop $instance4
Start-Sleep -s 30
ServiceStop $instance5
Start-Sleep -s 30

#Need to restart TM1 App server because Ops Console stops working without the App server bounce
ServiceStop "IBM Cognos TM1"

#ServiceStop ctmag
Start-Sleep -s 10
RenameFile("D:\Data\NIPT\Logs\tm1server.log")
RenameFile("D:\Data\Finance\Logs\tm1server.log")
RenameFile("D:\Data\Sales\Logs\tm1server.log")
RenameFile("D:\Data\Finance_OPS\Logs\tm1server.log")
RenameFile("D:\Data\SBC\Logs\tm1server.log")

Start-Sleep -s 10
#ServiceStart ctmag
ServiceStart $instance1
Start-Sleep -s 10
ServiceStart $instance2
Start-Sleep -s 10
ServiceStart $instance3
Start-Sleep -s 30
ServiceStart $instance4
Start-Sleep -s 30
ServiceStart $instance5
Start-Sleep -s 30

# Start the App server
ServiceStart "IBM Cognos TM1"


#ServiceStart ctmag
#Databackup "\\$env:COMPUTERNAME\E$\TM1Data\QCT_FIN_R12\Data"
#ServiceStop qct_fin_reporting_r12
#Databackup "\\$env:COMPUTERNAME\E$\TM1Data\QCT_FIN_REPORTING_R12\Data"
}
catch
{
#Send-MailMessage -to recipient@company.com -subject "error occured on $env:COMPUTERNAME" -from $env:COMPUTERNAME@company.com -Priority High -body "Error occured. Error message is $_.Exception.Message" -smtpserver smtphost.company.com
Send-MailMessage -to recipient@company.com -subject "Error occured on $env:COMPUTERNAME" -from $env:COMPUTERNAME@company.com -Priority High -body "Error occured: TM1 instances could not start. Error message is $Error" -smtpserver smtp.company.com
}

if ((Get-Service "IBM Cognos TM1").status -ne "Running") 
{ 
  Send-MailMessage -to recipient@company.com -subject "Error occured on $env:COMPUTERNAME" -from $env:COMPUTERNAME@company.com -Priority High -body "Error occured: TM1 instances could not start. Error message is $Error" -smtpserver smtp.company.com 
}
#Waiting for the TM1 ready status in tm1server.log, parse every 180 seconds

check_string "D:\Data\NIPT\Logs\tm1server.log" $instance1
check_string "D:\Data\Sales\Logs\tm1server.log" $instance2
check_string "D:\Data\Finance\Logs\tm1server.log" $instance3
check_string "D:\Data\Finance_OPS\Logs\tm1server.log" $instance4
check_string "D:\Data\SBC\Logs\tm1server.log" $instance5
