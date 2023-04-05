try 
        {

$FolderPath = "D:\temp"
$Password = "1Got2Finance3"
$GpgPath = 'D:\Program Files\GnuPG\bin\gpg.exe' 
    
            foreach($file in Get-ChildItem -Path $FolderPath -Filter '*.pgp')
            { 
            $Command = "gpg.exe -d --pinentry-mode loopback --passphrase 1Got2Finance3 -o D:\temp\$file.txt D:\temp\$file"
            Invoke-Expression $Command
            } 
            
        } 
        catch 
        { 
            Write-Error $_.Exception.Message 
        } 
     