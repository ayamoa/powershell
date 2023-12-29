#Retrieve members from a group and add it to other group 

Start-Transcript -path "Path\ADD-Members-Group.logs"
#Retrieve Members from GROUP_NAME by selecting only users'UID or whatever you want
$Users = get-adgroup -filter {Name -like "GROUP_NAME_HERE"} | Get-ADGroupMember | select SamAccountName
$Users = $Users.SamAccountName

#For each user in $Users do following command
foreach ($user in $Users) {

    $ADUser = Get-ADUser -Filter "SamAccountName -like '$user'" | Select-Object SamAccountName
    Add-ADGroupMember -Identity "Group Destination" -Members $ADUser

}

Stop-Transcript
