$minimumCertAgeDays = 30
$timeoutMilliseconds = 10000
#$urls = get-content .\check-urls.txt
$logfile="$destination\Check_URLs.txt"
$recipients = @("ILMN-Role-Cognos-Administrators@illumina.com")
#$url="https://datagovernance.illumina.com"

[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
Write-Host "Script run on $(get-date)" | Out-File $logfile -Append
Write-Host "======================================="

foreach ($url in $urls)
{
 Write-Host Checking $url -f Green
    $req = [Net.HttpWebRequest]::Create($url)
    $req.Timeout = $timeoutMilliseconds
    $req.AllowAutoRedirect = $false
    try {$req.GetResponse() |Out-Null} catch {Write-Host Exception while checking URL $url`: $_ -f Red}
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
        Write-Host Cert for site $url expires in $certExpiresIn days [on $expiration] -f Green | Out-File $logfile -Append
    }
    else
    {
        Write-Host WARNING: Cert for site $url expires in $certExpiresIn days [on $expiration] -f Red | Out-File $logfile -Append
        Write-Host Threshold is $minimumCertAgeDays days. Check details:`nCert name: $certName -f Red | Out-File $logfile -Append
        Send-MailMessage -to $recipients -subject "Cert $url expires in $certExpiresIn days [on $expiration]" -from DIADevOpsAdmin@illumina.com -Priority High -body "Cert $url expires in $certExpiresIn days [on $expiration]" -smtpserver smtp.illumina.com
        Write-Host Cert public key: $certPublicKeyString -f Red | Out-File $logfile -Append
        Write-Host Cert serial number: $certSerialNumber`nCert thumbprint: $certThumbprint`nCert effective date: $certEffectiveDate`nCert issuer: $certIssuer -f Red | Out-File $logfile -Append
    }
    Write-Host | Out-File $logfile -Append
    rv req
    rv expiration
    rv certExpiresIn
 }

 