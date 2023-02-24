#Script showing connection (like RDP) on servers in HTML report for Xymon


####THIS IS THE PRECONFIG OF MONTIRORING SOFTWARE Hobbit ####
$color = 'red'
$bbdate = get-date -uformat "%d/%m/%Y"
$bbtime = get-date -uformat "%H:%M"
$bbcolumn = 'sessions'
$Severity = "Warning"

# Start of detailed report
$header = "En-tete du message par defaut`n"


#Variables
$Time1 = "04"
$Time2 = "12"
$hostname = hostname
$Today = Get-Date


#HTML report start TAB
$hdtab = "<HTML><TABLE BORDER=1 CELLPADDING=5><TR><TH>HostName</TH><TH>Account</TH><TH>Name</TH><TH>Session Name</TH><TH>ID session</TH><TH>State</TH><TH>Time Connection</TH><TH>Logon Time</TH><TH>CRITICITY</TH></TR>"


#Convert string data from quser to object data in order to work with
Function Get-Quser ($quser) {

#Request to see connection 
$Quser = quser
$Quser = $Quser | ForEach-Object -Process {$_ -replace '\s{2,20}',','} | Convertfrom-Csv 

#Look system Culture

    foreach ($user in $Quser) {


        $account = $user.USERNAME.Replace(">","")
        $username = Get-ADUser -Identity $account -Properties Name
        $username = $username.Name 
        $Logon = Get-date $($user.'LOGON TIME')
        $Logon


        ####Logon Time Calcul (using TimeStamp here)
        $Time =  $Today - $Logon
        $Duration = ($Time.Days," Days  ", $Time.Hours,":",$Time.Minutes,":",$Time.Seconds)

        $State = $user.STATE.Replace("Disc","Disconnect")
        $Sessionname = $user.SESSIONNAME
        $ID = $user.ID
        

        #Calcul Severity 
          
        if ($user -eq $null){
            $color = "green"
            $header = "No long active connection in servers`n"
        }
        #If the timesession is greater than the variable Time1 and less than Time2 so it's a Warning 
        elseif ($Time.TotalHours -ge $Time1 -and $Time.TotalHours -le $Time2)
        {
            $Severity = "Warning"
            $color ="yellow"
            $board
        }
        #If timesession is greater than Time2 it's an Alert
        elseif ($Time.TotalHours -ge $Time2)
        {
            $Severity = "Alert"
            $color ="red"
            $board

        }
        else 
        {
            $Severity = "Normal"
            $color =""
        }


        ####PSCUSTOMOBJECT
        $Tableau = @()
        $Tableau = [PSCustomObject]@{
            Account = $account
            Username = $username
            SessionName = $SessionName
            Hostname = $hostname
            ID = $ID
            State = $State
            ConnectionTime = $Duration
            Login = $Logon
            Severity = $Severity
            Color = $color
        }
  
        ####Final board
        $board = $tableau | foreach {
            $Account = $account
            $Name = $username
            $Session_Name = $SessionName
            $HostName = $hostname
            $id = $_.ID
            $state = $State
            $ConnectionTime = $Duration
            $Login = $Logon
            $Criticity = $Severity
            $color = $color
        }

        $HtmlColor= "<pre style='color:$color'>"

        #Board construction with data
       $hdtab = $hdtab + "<TR><TD>$HostName</TD><TH>$HtmlColor$Account</TH><TH>$HtmlColor$Name</TH><TD>$HtmlColor$Session_Name</TD><TD>$HtmlColor$id</TD><TD>$HtmlColor$state</TD><TD>$HtmlColor$ConnectionTime</TD><TD>$HtmlColor$Login</TD><TH>$HtmlColor$Criticity</TH></pre></TR>"
    }


   
    #Export Data to HTML file with all data      
    Out-File -filepath 'C:\Temp\Quser.HTML' -inputobject " $color $bbdate $bbtime $bbcolumn`n<pre><P ALIGN=`"LEFT`">  for the last $ConnectionTime Hours $hdtab </P></pre>" -encoding utf8
    
    ####THIS is teh output if you're using Xymon too
    #out-file -filepath "$env:BBEXT\$bbcolumn" -inputobject "$color $bbdate $bbtime $bbcolumn`n<pre><P ALIGN=`"LEFT`">  for the last $ConnectionTime Hours $hdtab </P></pre>" -encoding utf8

}

#Call the function for the script to work
Get-Quser $Quser




