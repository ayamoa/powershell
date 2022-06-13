#Function to send data from a server to an other server


#$device = Import-Csv -Path "" -Delimiter ";" 
$deviceJSON = $null

$NonCompliantDevicesFilepaths = Get-ChildItem -Filter *.Csv # All csv in same repo


function SendTo-SysLog ($value) {
    
    #where to send
    $syslogIP = "IPSERVER"
    $syslogPort = 514
    $srcHost  = $env:computername + "." + $env:USERDOMAIN
    $date   = "date=`"$(Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff")`""
   
    #choose what to send
    $header =  $date + $srcHost + '"tags" = "dhcplog", ' + $value
    

    # Convert message to array of ASCII bytes.
    $bytearray = $([System.Text.Encoding]::ASCII).getbytes($header)
    if ($bytearray.count -gt 996) { $bytearray = $bytearray[0..995] }

    # Send the message... 
    $UdpClient = New-Object System.Net.Sockets.UdpClient 
    $UdpClient.Connect($syslogIP,$syslogPort)
    $UdpClient.Send($bytearray, $bytearray.length) | out-null
    $UdpClient.close()

}

$NonCompliantDevicesFilepaths | foreach {
    $Devices = Import-Csv -Path $_.FullName -Delimiter ";"

    #send one request per device found in CSV
    foreach ($deviceJSON in $Devices) {
        
        $deviceJSON = $deviceJSON | Select Name, <#@{Name= "IP"; Expression={$_.Ip.IPAddressToString}}#>IP, Mac, <#@{Name="ConnectionDate"; Expression={$Intrusion.ConnexionDate.GetDateTimeFormats()[54]}}#> ConnexionDate, <#@{Name="ExpirationDate"; Expression={$Intrusion.ExpirationDate.GetDateTimeFormats()[54]}}#> ExpirationDate, Scope, Vendor | ConvertTo-Json
        $deviceJSON = $deviceJSON -replace(":  ","=")
        SendTo-SysLog -value ($deviceJSON) 
    
    }
}

$deviceJSON
