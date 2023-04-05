#$Server = "ussd-dev-cgsb11"

Param (
    [string]$Server = $( Read-Host "Enter the server host name " )
     )

cls

$ServerInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Server 
#Get-WmiObject -Namespace "root\cimv2" -Class Win32_Process -Impersonation 3 -Credential `FABRIKAM\administrator -ComputerName $Computer
$CPUInfo = Get-WmiObject -Class Win32_Processor -ComputerName $Server 
$OSInfo = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Server  
$AvailableMemory = Get-WmiObject CIM_PhysicalMemory | Measure-Object -Property capacity -Sum | % {[math]::round(($_.sum / 1GB),2)}  
$TotalVirtualMemory = [math]::round($OSInfo.TotalVirtualMemorySize / 1MB, 2)
$FreeMemory = [math]::round($OSInfo.FreePhysicalMemory / 1MB, 2) 
$Cores = $CPUInfo.NumberofCores
$ServerName = $CPUInfo.SystemName
$ProcessorName = $CPUInfo.Name
$OSVersion = $OSInfo.Caption

 switch ($ServerInfo.Model) { 
                     
                    # Check for Hyper-V Machine Type 
                    "Virtual Machine" { 
                        $MachineType="VM" 
                        } 
 
                    # Check for VMware Machine Type 
                    "VMware Virtual Platform" { 
                        $MachineType="VM" 
                        } 
 
                    # Check for Oracle VM Machine Type 
                    "VirtualBox" { 
                        $MachineType="VM" 
                        } 
 
             
                    # Otherwise it is a physical Box 
                    default { 
                        $MachineType="Physical" 
                        } 
                    } 

echo "==============VM/OS Version================="
echo "$Server is a $MachineType"
echo "$Server is on $OSVersion"
echo "==============Memory================="
echo "RAM on the $Server is $AvailableMemory GB"
echo "Total Available RAM on the $Server is $FreeMemory GB"
echo "Total Available RAM on the $Server is $TotalVirtualMemory GB"
echo "==============CPU Info================="
echo "Total number of Cores on the $Server is $Cores"
#echo "Processor Manufacturer on the $Server is $ProcessorName"
