#Stops the service $ServiceName in the lois
#Get-Service -Name "IBM Cognos:9305" -ComputerName (Get-Content \\ussd-file\users\transfer\rraghavan\Cognos_Servers.txt) | Stop-Service -WhatIf

#Get-Service -Name "IBM Cognos:9305" -ComputerName (Get-Content \\ussd-file\users\transfer\rraghavan\Cognos_Servers.txt)

#$p = Get-Process -Name "java" -ComputerName (Get-Content \\ussd-file\users\transfer\rraghavan\Cognos_Servers.txt)
#Enter the computer name in the .txt file on which the services need to be started
$computers = Get-Content \\ussd-file\users\transfer\rraghavan\Cognos_Servers.txt
$ServiceName = "IBM Cognos:9305"
ForEach ($computer in $computers)
{
  #$Svc_status = Get-Service -Name "IBM Cognos:9305" -ComputerName  $computer | Select status
  $Svc_status = Get-Service -Name $ServiceName -ComputerName $computer
    
   if ($Svc_status.Status -eq "Stopped")
   {
  
    Write-Host "$(Get-Date): Service $ServiceName was already stopped on $computer"
    return
    }
 
#  Restart-Service -InputObject $(Get-Service -Computer $computer -Name service1);
   if ($Svc_status.Status -eq "Running")
   {
#     Stop-Service $ServiceName -Computer $computer 
     Write-Host "$(Get-Date): Stopping the service $ServiceName on $computer........" 
     Get-Service -Name $ServiceName -ComputerName $computer | Stop-Service -WarningAction SilentlyContinue
     
     " ---------------------- " 
      Start-Sleep -s 5
      $Svc_status = Get-Service -Name $ServiceName -ComputerName $computer
       if ($Svc_status.Status -eq "Stopped")
       { 
         Write-Host "$(Get-Date): $ServiceName service is already stopped"
       } else
       {
        do 
          { 
           Start-Sleep -s 2
           }
           until ((get-service $service).status -eq 'Stopped')
           echo "Starting $ServiceName on $computer"
       }
   }
     Write-Host "$(Get-Date): Service $ServiceName is now stopped"
     return
 }

  if ($Svc_status.Status -eq "Stopped")
  { 
  Write-Host "$(Get-Date): $ServiceName service is already stopped" | out-File c:\temp\log.txt - Append
  }
 



 <#

 if ($arrService.Status -ne "Running"){
 Start-Service $ServiceName
 Write-Host "Starting " $ServiceName " service" 
 " ---------------------- " 
 " Service is now started"
 }
 if ($arrService.Status -eq "running"){ 
 Write-Host "$ServiceName service is already started"
 }
 }
 #>