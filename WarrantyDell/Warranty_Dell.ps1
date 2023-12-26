
#PROXY CONFIGURATION / could be usefull for you
[system.net.webrequest]::defaultwebproxy = new-object system.net.webproxy('PROXY')
[system.net.webrequest]::defaultwebproxy.credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
[system.net.webrequest]::defaultwebproxy.BypassProxyOnLocal = $true
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

try {
    #HERE I call CSV that contains all data from our GLPI database ( I need those informations : name, serial, warranty_duration, Warranty_Start_Date, warranty_value, type, Location, Model, State )
     $CSV_Serial_Dell = Get-Content ".CSV" -ErrorAction Stop | ConvertFrom-Csv | Where-Object {$_.Manufacturers -match "Dell.*"}
     $CSV_Monitor_Dell = Get-Content ".CSV" -ErrorAction Stop | ConvertFrom-Csv | Where-Object {$_.Manufacturers -match "Dell.*"}
}
Catch{
    #Get-Error
    Break
}


#VARIABLE
$date = Get-date -f "yyyy-MM-dd"
$Dell_response_Table = @()
$RegexDate = "^\d{4}-\d{2}-\d{2}$"

$For_Dell = $CSV_Serial_Dell + $CSV_Monitor_Dell #Here you merge all your CSVs
$For_Dell_Prod = $For_Dell | Where{$_.State -ne "Retired"} # Choosing all devices except those with Retired tag 
$AllServiceTag = $For_Dell_Prod | Select-Object name, serial, warranty_duration, Warranty_Start_Date, warranty_value, type, Location, Model, State
$warranty_start = $AllServiceTag.Warranty_Start_Date 

#For DELL
#URL d'auth
$AuthURI = "https://apigtwb2c.us.dell.com/auth/oauth/v2/token"
#URL pour récup la garantie d'un équipement
$AssetURI = "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements"


###########################################
#GET API AND KEYSECRET FROM 

#Retrieve Keys & API
$APIKEY = (Get-Content -Path '\KEYs.txt')[0]
$KEYSecret = (Get-Content -Path '\KEYs.txt')[1]

#Encrypted API to clear text
#$APIKEY
$APIstring = ConvertTo-SecureString -String $APIKEY
$API = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($APIstring))

#Encrypted KEY to clear text
#$KEYSecret
$KEYstring = ConvertTo-SecureString -String $KEYSecret
$KEY = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($KEYstring))

###########################################


function DellSupportRequest ($ServiceTagList) {

Start-Transcript -Path "PATH.$date.txt" 

    #Make request to Dell Support
    if (!$token) {
        $OAuth = "$API`:$KEY"
        $Bytes = [System.Text.Encoding]::ASCII.GetBytes($OAuth)
        $EncodedOAuth = [Convert]::ToBase64String($Bytes)
        $Headers = @{ }
        $Headers.Add("authorization", "Basic $EncodedOAuth")
        $Authbody = 'grant_type=client_credentials'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $AuthResult = Invoke-RestMethod -Method Post -Uri $AuthURI -Body $AuthBody -Headers $Headers
        $token = $AuthResult.access_token
        $headers = @{"Accept" = "application/json" }
        $headers.Add("Authorization", "Bearer $token")
    }

    #Principal 
    $Dell_response = [System.Collections.ArrayList]@()
    #Secondary()
    $CSV_For_ITS = [System.Collections.ArrayList]@()


    #Construct data to send to Dell with extract csv (GLPI data) 
    foreach ($object in $ServiceTagList) {
        $params = @{ }
        $params = @{servicetags = $object.serial; Method = "GET" }
        if( [string]::IsNullOrEmpty($object.serial)) {
            Write-Host "Device Name   : $($object.name)" -ForegroundColor Cyan
            Write-Host "Service Tag   : No Service Tag!" -ForegroundColor Red   
        }
      

            ############### WARRANTY DATA RETRIEVE ###############
            #Ordering Response with specific select informations about warranties
            $response = Invoke-RestMethod -Uri $AssetURI -Headers $headers -Body $params -Method Get -ContentType "application/json"
            $servicetag = $response.servicetag
            
            #Response from Dell with all informations about Warranties (Type, Date ...)
            $ResponseWarranties = $response.entitlements

            #Get last End date warranty
            $endDateMax = $ResponseWarranties.EndDate | Measure-Object -Maximum
            $Dell_EndDate = $endDateMax.Maximum | Get-Date -f "yyyy-MM-dd"
            

            #Get last support description/type of warranty
            $Support = ($ResponseWarranties | Where-Object {$_.endDate -match $endDateMax.Maximum}).serviceLevelDescription

            #Get Ship Date
            $Dell_ShipDate = $response.shipDate
            $Dell_ShipDate = if($Dell_ShipDate){$Dell_ShipDate | Get-Date -f "yyyy-MM-dd"} else {"NA"}
            ############### WARRANTY DATA RETRIEVE ###############



            #YOU PROBABLY WON'T NEED THIS PART
            ############### Organize data ###############  ITS = ITSupport = GLPI
            #Convert String to DateFormat, calculate End Warranty for Glpi device ( using Warranty duration = $object.warranty_duration)
            $start_ITS = $object.Warranty_Start_Date
            $ITS_Start = if($start_ITS -match $RegexDate) {[DateTime]::ParseExact($start_ITS, "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture)} else{$ITS_Start = "Null"} 
            
            $ITS_Months = $object.warranty_duration
            $ITS_END = if ($ITS_Start -as [datetime]){$ITS_Start.AddMonths($ITS_Months) | Get-Date -f "yyyy-MM-dd"}else {"Null"}
            
            #Calcul if Date between DELL support and GLPI are compliant
            if ($ITS_Start -match "Null" -or $ITS_END -match "Null"){
				$compliance_Data = "No"
			}else {    
                if ([datetime]$Dell_ShipDate -le $ITS_Start.AddMonths(1) -or $Dell_EndDate -ge $GLPI_END.AddMonths(1) -or $Dell_EndDate -ge $ITS_END.AddMonths(-1) ){
                    $compliance_Data = "Yes"
                }else {$compliance_Data = "No"}
            }


            #Output on console for every devices
            Write-Host "Service Tag   : $servicetag"
            #Write-Host "Support Level : $Support"


            #DELL : Is it COMPLIANT or NOT ?
            if (!($Dell_EndDate -match $RegexDate)){
                $Dell_EndDate = "Null"
                $Compliant = "No"}
            elseif ($date -ge $Dell_EndDate) { 
                $Compliant = "No"}
            else { 
                $Compliant = "Yes"}
            #Back line
            "`r"

            #Date better formatting for ITS_Start
            $ITS_Start = if ($ITS_Start -as [datetime]) {$ITS_Start| Get-Date -f "yyyy-MM-dd"}
            
            
            #Give ERROR CODE to No SERVICETAG
            if ($servicetag -eq $null){ #OR if !($servicetag){
                $Err = "Err404 - Servicetag not found in ITSupport"
                $servicetag = "Null"

            #Give ERROR CODE to no Warranty Dell            
            }elseif ($Dell_EndDate -eq $null -or $Dell_EndDate -lt $date){  #OR (!($Dell_EndDate) -or $Dell_EndDate -lt $date){
                $Support = "Null" 
                $Err = "Err406 - No warranty or warranty has expired"

            #Give ERROR CODE to no Warranty ITS
            }elseif (!($ITS_Start -match $RegexDate -and $object.Type -eq "Monitor")) {
                $ITS_Start = "Null" 
                $Err = "Err502 - No warranty date in ITSupport"
            }else {$Err = "Compliant"}

            
        ##### GATHER ALL INFORMATIONS in one board
        #PscustomObject centralizing all data and export to CSV
        $Dell_response += [PSCustomObject]@{
            ITS_Name =  $object.name
            ITS_servicetag = $servicetag
            Dell_Device = $response.productLineDescription
            ITS_Type = $object.type #Monitor / server / laptop
            ITS_Warranty_Start = $ITS_Start
            ITS_Warranty_Months = $ITS_Months
            ITS_Warranty_End = $ITS_END
            Dell_ShipDate = $Dell_ShipDate
            Dell_EndWarranty = $Dell_EndDate
            Support_Type = $Support
            Under_warranty = $Compliant
            Alignment_DELL_VS_ITS = $compliance_Data
            Compliance_ERROR = $Err
            Date = $date
            Location = $object.Location
            Model = $object.Model
            State = $object.State
        }
        
    }           
    
  
    $Dell_response | Export-Csv -Path "PATH\TO.$date.csv" -Encoding UTF8 -NoTypeInformation -Delimiter ";"
    $Dell_response | Export-Csv -Path "PATH\TO.csv" -Encoding UTF8 -NoTypeInformation -Delimiter ";" 
    
    #If you want to implement the board to a webpage, that's a JSON export
    $Dell_response | Select ITS_Name, ITS_servicetag, ITS_Type, ITS_Warranty_Start, ITS_Warranty_Months, ITS_Warranty_End, Dell_EndWarranty, Support_Type, Under_warranty, Location, Model, State, Alignment_DELL_VS_ITS,Date,Compliance_ERROR | ConvertTo-Json | Out-File -FilePath "PATH\data.json"
    

Stop-Transcript

}

DellSupportRequest $AllServiceTag

