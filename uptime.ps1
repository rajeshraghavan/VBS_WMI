#Find uptime for a remote host

Param (
    [string]$Computer = $( Read-Host "Enter the host name for which uptime needs to be found " )
     )

$Credential = [System.Management.Automation.PSCredential]::Empty
 $boot_time = Get-WmiObject win32_operatingsystem -ComputerName $Computer -ErrorAction Stop -Credential $Credential
 $BootTime = $boot_time.ConvertToDateTime($boot_time.LastBootUpTime)
 $Uptime = $boot_time.ConvertToDateTime($boot_time.LocalDateTime) - $boottime
 echo "Last bootup date for $Computer is "
 $operatingSystem = Get-WmiObject Win32_OperatingSystem -ComputerName $Computer              
    [Management.ManagementDateTimeConverter]::ToDateTime($operatingSystem.LastBootUpTime)    

echo "=========================================="
echo "Uptime for the host $Computer "
echo $Uptime | select Days, Hours, Minutes
