#ayamoa
#11/3/2023
#Sort files/photos in a folder by date. 1 folder created by months
#You can create by years, months and days.


#Get files from the directory.
$files = Get-ChildItem 'SourcePATH' -Recurse | where {!$_.PsIsContainer}
 
# List files from folder and count.
$files
$files.count
 
# Choose a destination folder where all months & years folders will be created. 
$DestinationFolder = 'DestPATH'
 
foreach ($file in $files){

    # Get year and month of the file
    #Using LastWriteTime instead of creationdate because Creationdate is when file is upload on pc
    $year = $file.LastWriteTime.Year.ToString()
    $month = $file.LastWriteTime.Month.ToString()
    $day = $file.LastWriteTime.Day.ToString()
   
    # Out FileName, year and month
    $file.Name
    $year
    $month
    $day

    # Set Directory Path
    #You can remove + "\" + $year if its in a year folder already
    $Directory = $DestinationFolder + "\" + $year + "\" + $month + "\" + $day
    
    # Create directory if it doesn't exsist
    if (!(Test-Path $Directory)){
        New-Item $directory -type directory
        write-host " Folder $directory created"
    }
 
    # Move File to new location
    $file | Move-Item -Destination $Directory
}