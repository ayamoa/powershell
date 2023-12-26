#THAT method uses the session to encrypt data. SO IF YOU WANT to decrypt, it'll only work with the SAME SESSION on the SAME COMPUTER !!
#Api Encrypt
$API ="For the first time, put it here"
$APISecure = $API | ConvertTo-SecureString -AsPlainText -Force
$ASecured = $APISecure | ConvertFrom-SecureString
#$Asecured = " "

#KeySecret
$KEY = "For the first time, put it here"
$KEYSecure = $KEY | ConvertTo-SecureString -AsPlainText -Force
$KSecured = $KEYSecure | ConvertFrom-SecureString
#$KEYSecret = " "

$KEYs = $ASecured, $KSecured

$KEYs |  Out-file -FilePath "PATH\KEYs.txt"

########From Encrypted to Clear 
#$securestring = ConvertTo-SecureString -String $$ASecured
#$APIclear = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securestring))
#$APIclear

