#
#             Fetch folder info via deploy jobs::get
#             Examine each job for "FromTime" value
#             If a job's FromTime is earlier than "cutoffTime", skip the job
#                             Otherwise order the job
#

#---------------------------------------------------------------------------------------------------------------------+
#             Parameters:                                                                                                       |
#                             folder|fn                                             Name of the folder to process                                                             |
#                             ctmName|ctm                                  Name of the Control-M Server                                                              |
#                             cutoffTime|time                              The time to use for determining if a job should be ordered or not                         |
#                                                                                                             'now" is the default and uses the current system time                                     |
#                                                                                                             'hh:mm" can be specified in 24-hour format, for any other time                            |
#                             pswdfile|pf                                        Fully-qualified path of a file containing the Control-M username and password.            |
#                                                                                                             If not specified, a rpompt is issued to cllect that information.                          |
#                                                                                                             The username is the first record and the password is the second record, for example:      |
#                                                                                                             ctmuser                                                                                   |
#                                                                                                             mypassword                                                                                |
#                             method                                                'rest' or 'cli' to indicate if the installed and configured "ctm" cli is used             |
#                                                                                                             or direct REST API                                                                        |
#                             jobFormat|jf                     The format of job data retrieved from Control-M                                           |
#                             endpoint                                             The fully-qualified name or IP address of the Control-M Enterprise Manager, used only     |
#                                                                                                             if method='rest' has been selected.                                                       |
# Usage: .\Order_jobs.ps1 -fn Admin_rraghavan -ctm ControlM_DEV -time "13:00" -method cli -jf xml
#---------------------------------------------------------------------------------------------------------------------+

param(
    [Parameter(Mandatory=$true)][Alias("fn")][String]$folder,
    [Parameter(Mandatory=$true)][Alias("ctm")][String]$ctmName,
    [Parameter(Mandatory=$false)][Alias("time")][String]$cutoffTime = 'now',
    #Parameter(Mandatory=$false)][Alias("time")][String]$cutoffTime = 'HH:MM'
                [Parameter(Mandatory=$false)][Alias("pf")][String]$pswdFile,
                [Parameter(Mandatory=$false)][String]$method = 'rest',
                [Parameter(Mandatory=$false)][Alias("jf")][String]$jobFormat = 'json',
                [Parameter(Mandatory=$false)][Alias("ep")][String]$endpoint = 'ec2-52-32-170-215.us-west-2.compute.amazonaws.com'
)

function CTM-Login 
{
                #
                #             Get username and password for CTM login
                #
                param ([String]$username,[String]$password, [String]$ctmURL)
                
                $login_data = @{ 
                                username = $username; 
                                password = $password}

                try
                {              
    #------------------------------------------------------------------------------------
    #  To accept self-signed certificates uncomment next line
    #
                                $login_res = Invoke-RestMethod -SkipCertificateCheck -Method Post -Uri $ctmURL/session/login  -Body (ConvertTo-Json $login_data) -ContentType "application/json"
                }
                catch
                {
                                $_.Exception.Message
                                $error[0].ErrorDetails     
                                $error[0].Exception.Response.StatusCode
                                exit
                }
                
                $token = $login_res.token
                return $token
}

function Get-Credentials 
{
                if ($pswdFile -eq '') {
                                $userName = Read-Host "Enter username for Control-M"
                                $securepswd = Read-Host "Enter Password" -AsSecureString
                                $password = ConvertFrom-SecureString -SecureString $securepswd -AsPlainText}
                else {
                                $credsInFile = Get-Content -Path $pswdFile -TotalCount 2
                                $userName = $credsInFile[0]
                                $password = $credsInFile[1]
                }
                
                $creds = @($userName, $password)
                return $creds
}

function Order-Job
{
                param ([String]$method, [String]$folderName, [String]$jobName)

                if ($method.ToLower() -eq "rest") {          
                                $order_data = @{ 
                                                ctm = $ctmName; 
                                                folder = $foldername;
                                                jobs=$jobName}
                
                                try
                                {              
                                                $order_res = Invoke-RestMethod -SkipCertificateCheck -Method Post -Uri $ctmURL/run/order -Body (ConvertTo-JSON $order_data) -Headers $headers -ContentType "application/json" 
                
                                }
                                catch
                                {
                                
                                                Write-Host "Run Order failed: "  
                                                $order_res
                                                $error[0].ErrorDetails     
                                                $error[0].Exception.Response.StatusCode
                                                exit
                                }
                }
                else {
                                $ctmCmd = 'ctm run order ' + $ctmName + ' ' + $folder + ' ' + $jobName
                                $ctmJSON = (cmd.exe /c $ctmCmd) | Out-String
                }
}

if ($cutoffTime -eq "now") {
                $timeNow = Get-Date -uformat %R}
else {
                $timenow = $cutoffTime
}
Write-Host "Processing folder: $folder on Control-M server: $ctmName with cutoff time: $timenow"

if ($jobFormat.ToLower() -eq 'json') {
                Write-Host "Using JSON format"
}
else {
                Write-Host "Using XML format"
}

if ($method.ToLower() -eq "rest") {
                Write-Host "Using REST method"
                $ctmCreds = Get-Credentials
                
                $username = $ctmCreds[0]
                $password = $ctmCreds[1]
                $ctmURL = "https://" + $endpoint + ":8443/automation-api"
   
                $token = CTM-Login -username $username -password $password -ctmURL $ctmURL
                "Logged in successfully
                "
                $headers = @{ Authorization = "Bearer $token"}
                if ($jobFormat.ToLower() -eq 'json') {
                                
                                $deploy_data = @{ 
                                                ctm = $ctmName; 
                                                folder = $folder}
                }
                else {
                                $deploy_data = @{ 
                                                format = "xml";
                                                ctm = $ctmName; 
                                                folder = $folder}
                }
                try
                {              
                                $deploy_res = Invoke-RestMethod -SkipCertificateCheck -Method Get -Uri $ctmURL/deploy/jobs -Body ($deploy_data) -Headers $headers -ContentType "application/json" 
                
                }
                catch
                {
                                
                                Write-Host "Deploy GET failed: "               
                                $deploy_res
                                $error[0].ErrorDetails     
                                $error[0].Exception.Response.StatusCode
                                exit
                }
                Write-Host "Retrieved jobs successfully"
                if ($jobFormat.ToLower() -eq 'json') {
                                $folderObj = $deploy_res.PSObject.Properties.Value
                }
                else {
                                $ctmXML = $deploy_res.OuterXML
                }
}
else {
                Write "Using CLI method"
                if ($jobFormat.ToLower() -eq 'json') {
                                $ctmCmd = 'ctm deploy jobs::get -s "ctm=' + $ctmName + '&folder=' + $folder + '"'
                                $ctmJSON = (cmd.exe /c $ctmCmd) | Out-String
                                $ctmObj = ConvertFrom-Json -InputObject $ctmJSON
                                $folderObj = $ctmObj.PSObject.Properties.Value
                }
                else {
                                $ctmCmd = 'ctm deploy jobs::get xml -s "ctm=' + $ctmName + '&folder=' + $folder + '"'
                                $ctmXML = (cmd.exe /c $ctmCmd) | Out-String
                }
}

$jobInfo = @()

if ($jobFormat.ToLower() -eq 'json') {
                foreach($folder_properties in $folderObj.PsObject.Properties)
                {
                                Write-Host "`tScanning object: " $folder_properties.Name $folder_properties.PsObject.Properties.Value.Type
                                $ctmJob = $folder_properties.Name
                                $fromTime = $folder_properties.Value.When.FromTime
                                if ($fromTime -ne $null) {              
                                                $HH = $fromTime.Substring(0, 2)
                                                $MM = $fromTime.Substring(2,2)
                                                $jobFromTime = $HH + ":" + $MM
                                                $TimeDiff = New-TimeSpan $timeNow $jobFromTime 
                                                if ($TimeDiff.TotalSeconds -lt 0) {
                                                                write-host "`n`tSkipping job:  $ctmJob `n"}
                                                else {
                                                                Write-Host "`nOrder job: $ctmJob `t FromTime: $jobFromTime `n"
                                                                Order-Job -method $method -folderName $folder -jobName $ctmJob
                                                                $jobInfo += $ctmJob
                                                }
                                }
                                else {
                                                Write-Host "`nOrder job: $ctmJob `t FromTime: $jobFromTime `n"
                                                Order-Job -method $method -folderName $folder -jobName $ctmJob
                                                $jobInfo += $ctmJob
                                }
                }
}
else {
                $ctmJobsXML = Select-XML -Content $ctmXML -XPath "//JOB"
                foreach($folder_job in $ctmJobsXML)
                {
                                Write-Host "`tScanning object: " $folder_job.node.JOBNAME
                                $ctmJob = $folder_job.node.JOBNAME
                                if ($folder_job.node.TIMEFROM -ne $null) {
                                                $HH = $folder_job.node.TIMEFROM.Substring(0, 2)
                                                $MM = $folder_job.node.TIMEFROM.Substring(2,2)
                                                $jobFromTime = $HH + ":" + $MM
                                                $TimeDiff = New-TimeSpan $timeNow $jobFromTime 
                                                if ($TimeDiff.TotalSeconds -lt 0) {
                                                                write-host "`n`tSkipping job:  $ctmJob `n"}
                                                else {
                                                                Write-Host "`nOrder job: $ctmJob `t FromTime: $jobFromTime `n"
                                                                Order-Job -method $method -folderName $folder -jobName $ctmJob
                                                                $jobInfo += $ctmJob
                                                }
                                }
                                else {
                                                Write-Host "`nSkip job: $ctmJob `t FromTime: $jobFromTime `n"
 #                                               Order-Job -method $method -folderName $folder -jobName $ctmJob
 #                                               $jobInfo += $ctmJob
                                }
                }
}

Write-Host "`nNumber of jobs ordered: " $jobInfo.Count
