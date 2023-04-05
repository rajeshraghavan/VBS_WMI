#Get-Service -Name "IBM Cognos:9305" -ComputerName (Get-Content \\ussd-file\users\transfer\rraghavan\Cognos_Servers.txt) | Stop-Service -WhatIf

#Get-Service -Name "IBM Cognos:9305" -ComputerName (Get-Content \\ussd-file\users\transfer\rraghavan\Cognos_Servers.txt)

#$p = Get-Process -Name "java" -ComputerName (Get-Content \\ussd-file\users\transfer\rraghavan\Cognos_Servers.txt)

$computers = Get-Content \\ussd-file\users\transfer\rraghavan\Cognos_Servers.txt
$ServiceName = "IBM Cognos:9305"
ForEach ($computer in $computers)
{
  #$Svc_status = Get-Service -Name "IBM Cognos:9305" -ComputerName  $computer | Select status
  $Svc_status = Get-Service -Name $ServiceName -ComputerName $computer
   if ($Svc_status.Status -eq "Running")
   {
  
    Write-Host "$(Get-Date): Service $ServiceName was already running on $computer"
    return
    }
 
#  Restart-Service -InputObject $(Get-Service -Computer $computer -Name service1);
   if ($Svc_status.Status -eq "Stopped")
   {
#     Stop-Service $ServiceName -Computer $computer 
     Write-Host "$(Get-Date): Starting the service $ServiceName on $computer........" 
     Get-Service -Name $ServiceName -ComputerName $computer | Start-Service -WarningAction SilentlyContinue
     
     " ---------------------- " 
      Start-Sleep -s 5
      $Svc_status = Get-Service -Name $ServiceName -ComputerName $computer
       if ($Svc_status.Status -eq "Running")
       { 
         Write-Host "$(Get-Date): $ServiceName service started successfully"
       } else
       {
        do 
          { 
           Start-Sleep -s 10
           echo "$(Get-Date): Starting $ServiceName on $computer"
          }
            until ((get-service $service).status -eq 'Running')
            echo "$(Get-Date): Stopping $ServiceName on $computer"
          }
       }
     Write-Host " $(Get-Date): Service $ServiceName is now running on $computer"  
     return
     
    

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