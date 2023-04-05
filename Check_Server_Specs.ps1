####################################################################################
#Query the specs of the servername (grab via the input)
#Author: rajeshr
#Usage: .\mdb.ps1 enter the servername when the script prompts
################################################################################

Param (
    [string]$Server = $( Read-Host "Enter the server host name " )
     )

#cls
$Fs=@{Label='Free Space'; expression={$_.freespace};formatstring='n0'}
$Sz=@{Label='Size'; expression={$_.Size};formatstring='n0'}

$ServerInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Server 
#Get-WmiObject -Namespace "root\cimv2" -Class Win32_Process -Impersonation 3 -Credential `FABRIKAM\administrator -ComputerName $Computer
$CPUInfo = Get-WmiObject -Class Win32_Processor -ComputerName $Server 
$MemInfo = Get-WmiObject -Class Win32_PhysicalMemory -ComputerName $Server
$OSInfo = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Server  
$AvailableMemory = Get-WmiObject CIM_PhysicalMemory | Measure-Object -Property capacity -Sum | % {[math]::round(($_.sum / 1GB),2)}       
$Space = Get-WmiObject win32_logicaldisk -ComputerName $Server

#$TotalPhysicalMemory = [math]::round($MemInfo.Capacity / 1MB, 2)
$TotalPhysicalMemory = (Get-WmiObject Win32_PhysicalMemory -Computer $Server | measure-object Capacity -sum).sum/1GB
$TotalVirtualMemory = [math]::round($OSInfo.TotalVirtualMemorySize / 1MB, 2)
$FreeMemory = [math]::round($OSInfo.FreePhysicalMemory / 1MB, 2) 
$Cores = $CPUInfo.NumberofCores
$ServerName = $CPUInfo.SystemName
$ProcessorName = $CPUInfo.Name
$OSVersion = $OSInfo.Caption
#$IpAddr=((ipconfig | findstr [0-9].\.)[0]).Split()[-1]
$IpAddr=(Test-Connection -ComputerName $Server -count 1).IPV4Address.ipaddressTOstring


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

echo "==============IP Address================="
echo "The IP address of $Server is $IpAddr"
echo "==============VM/OS Version================="
echo "$Server is a $MachineType"
echo "$Server is on $OSVersion"
echo "==============Memory================="
echo "Total Physical Memory on the $Server is $TotalPhysicalMemory GB"
echo "Total Available RAM on the $Server is $FreeMemory GB"
echo "Total Available Virtual Memory on the $Server is $TotalVirtualMemory GB"
echo "==============CPU Info================="
echo "Total number of Cores on the $Server is $Cores"
#echo "Processor Manufacturer on the $Server is $ProcessorName"
echo "==============Disk Info in GB================="

#echo $Space | Format-Table Name, $Fs, $Sz  -a 
echo $Space | Format-Table DeviceId, @{n="Size";e={[math]::Round($_.Size/1GB,2)}},@{n="FreeSpace";e={[math]::Round($_.FreeSpace/1GB,2)}}
