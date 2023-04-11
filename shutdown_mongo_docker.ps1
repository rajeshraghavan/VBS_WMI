 # Windows Containers on Server 2016 LTS does not properly signal containers on shutdown
# Gracefully shutdown the mongo process and then stop the container

# This script should be added as a Shutdown script
# Run gpedit.msc
# Under Computer Configuration / Windows Settings / Scripts (Startup/Shutdown),
# Double-click "Shutdown", change to the "PowerShell Scripts" tab and add this script.
# You may want to copy this script to a fixed location on your system instead of using it
# inside a specific Planning Analytics Workspace version.

$logfile="$PSScriptRoot\shutdown.log"

Add-Content -Encoding Unicode $logfile "Planning Analytics Workspace shutdown script invoked at $(Get-Date)"

if ((docker ps -q -f "name=mongo" | Measure-Object).Count -eq 1) 
{
	docker update --restart=no mongo *>> $logfile
	Write-Output "Stopping mongo"
	docker exec mongo mongo admin --eval "db.shutdownServer()" *>> $logfile
	Start-Sleep 2
	docker stop mongo *>> $logfile
	docker update --restart=always mongo *>> $logfile
} 
