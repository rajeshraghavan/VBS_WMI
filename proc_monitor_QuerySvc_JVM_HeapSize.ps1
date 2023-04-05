#####################################################
#Script to monitor JVM Heap size
#Author - rajeshr
#Date: 06/14/2018
#####################################################

function Get-TimeStamp {
    
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    
}

#Main
#$Process_Name="java"
#$PS_WS=Get-Process $Process_Name | select -first 1 | select WS -outvariable PS_WS

$users = "rraghavan@illumina.com"
$fromemail = "$Server_Name@illumina.com" 
$server = "smtp.illumina.com"
#$Proc_val=$PS_WS.WS
$proc_mem_threshold=10

$Servers = @("ussd-prd-cgap21", "ussd-prd-cgap22", "ussd-prd-cgap23", "ussd-prd-cgap24")

foreach ($Server in $Servers ) 
{
  #$f = get-item $file
  #$newpath = join-path $f.directoryname $($f.basename + "_new" + $f.extension) 
  #$Server=$env:computername

  #Check to make sure to grep for the JVM heap size

  $priv_memory=Get-WMIObject win32_Process -Computername $Server -Filter "Name='java.exe' "  | Sort PrivatePageCount | Where-Object {$_.CommandLine -match "Xmx12288m"}| Select Name,CommandLine,@{n="Private Memory(gb)";e={$_.PrivatePageCount/1gb}} | select -expand "Private Memory(gb)"
  $priv_memory1=[math]::Round($priv_memory)
  #$Server=$env:computername
    # if there is such a process found
  #$proc_mem_GB=$proc_val/1024/1024/1024
  #Write-Host "$(Get-Date): Query service JVM heap size utilization is $priv_memory GB" | out-File E:\Scripts\Logs\log.txt - Append
 Write-Output "$(Get-TimeStamp) Query service JVM heap size utilization (in GB) on $Server is $priv_memory" | out-File E:\Scripts\Logs\proc_log.txt -Append

  if ( $priv_memory1 -gt $proc_mem_threshold )
  {
    Write-Host "$(Get-Date): Query service JVM heap size utilization on $Server exceeded 10GB (80%)" | out-File E:\Scripts\Logs\proc_log.txt -Append
    Send-MailMessage -From "rraghavan@illumina.com" -to "rraghavan@illumina.com,cjayachand@illumina.com" -SmtpServer "smtp.illumina.com" -Subject "Query service JVM heap size utilization on $Server exceeded 10GB (80%)" -Body "Query service JVM heap size utilization on $Server exceeded 10GB (80%), Current utiulization is $priv_memory "
  }
}