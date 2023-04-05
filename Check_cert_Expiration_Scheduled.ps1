##################################################################################################
#Script to check the expiration of certificates for the URLs present in E:\Scripts\Check_urls.ini
# Check E:\Scripts\Logs\Check_URLs_log.txt for the output
#Author - rajeshr
#Date - 05/20/2020
##################################################################################################

$minimumCertAgeDays = 30
$timeoutMilliseconds = 10000
$urls = get-content "E:\Scripts\Check_urls.ini"
$logfile="E:\Scripts\Logs\Check_URLs_log.txt"
$recipients = @("ILMN-Role-Cognos-Administrators@illumina.com")
#$recipients = @("rraghavan@illumina.com")
#$url="https://datagovernance.illumina.com"
echo "Script run on $(get-date)" | Out-File $logfile -Append
echo "=======================================" | Out-File $logfile -Append
echo "" | Out-File $logfile -Append

[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
foreach ($url in $urls)
{
 echo "Checking $url" | Out-File $logfile -Append
    $req = [Net.HttpWebRequest]::Create($url)
    $req.Timeout = $timeoutMilliseconds
    $req.AllowAutoRedirect = $false
    try {$req.GetResponse() |Out-Null} catch {echo Exception while checking URL $url`: $_ | Out-File $logfile -Append}
    $certExpiresOnString = $req.ServicePoint.Certificate.GetExpirationDateString()

    [datetime]$expiration = [System.DateTime]::Parse($req.ServicePoint.Certificate.GetExpirationDateString())
    #Write-Host "Certificate expires on (datetime): $expiration"
    [int]$certExpiresIn = ($expiration - $(get-date)).Days
    $certName = $req.ServicePoint.Certificate.GetName()

    $certPublicKeyString = $req.ServicePoint.Certificate.GetPublicKeyString()
    $certSerialNumber = $req.ServicePoint.Certificate.GetSerialNumberString()
    $certThumbprint = $req.ServicePoint.Certificate.GetCertHashString()
    $certEffectiveDate = $req.ServicePoint.Certificate.GetEffectiveDateString()
    $certIssuer = $req.ServicePoint.Certificate.GetIssuerName()
    if ($certExpiresIn -gt $minimumCertAgeDays)
    {
        echo "Cert for site $url expires in $certExpiresIn days on $expiration " | Out-File $logfile -Append
    }
    else
    {
        echo "WARNING: Cert for site $url expires in $certExpiresIn days on $expiration " | Out-File $logfile -Append
        echo "Threshold is $minimumCertAgeDays days. Check details:`nCert name: $certName " | Out-File $logfile -Append
        Send-MailMessage -to $recipients -subject "Cert $url expires in $certExpiresIn days [on $expiration]" -from DIADevOpsAdmin@illumina.com -Priority High -body "Cert $url expires in $certExpiresIn days [on $expiration]" -smtpserver smtp.illumina.com
        echo "Cert public key: $certPublicKeyString " | Out-File $logfile -Append
        echo "Cert serial number: $certSerialNumber`nCert thumbprint: $certThumbprint`nCert effective date: $certEffectiveDate`nCert issuer: $certIssuer " | Out-File $logfile -Append
    }
    echo "" | Out-File $logfile -Append
    rv req
    rv expiration
    rv certExpiresIn
 }
 echo "========================================================" | Out-File $logfile -Append