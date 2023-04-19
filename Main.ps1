# Load the necessary assemblies for displaying input boxes
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

# Display the input box for the first input
$firstInput = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the source Computer name", "First Input")
$firstInputNoSpaces = $firstInput -replace ' ', ''

# Display the input box for the second input
$secondInput = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the destination Computer name", "Second Input")
$secondInputNoSpaces = $secondInput -replace ' ', ''

# Display the inputs without spaces to verify
Write-Host "Source Computer: $firstInput"
Write-Host "Destination Computer: $secondInput"
Write-Host "copying user profiles from $firstInputNoSpaces to $secondInputNoSpaces"
Start-Sleep -Seconds 1

$sourceComputer = $firstInputNoSpaces
$destinationComputer = $secondInputNoSpaces

# Define the UNC path to the remote computer's user folder location
$remoteUserFolderPath = "\\$sourceComputer\C$\Users"

# Get the folder names in the remote user folder path
try {
    $userFolders = Get-ChildItem -Path $remoteUserFolderPath -Directory
} catch {
    Write-Host "Error accessing remote computer: $sourceComputer"
    exit
}

# Initialize an empty array to store user folder names
$userFolderNames = @()

# Write out the user folder names and add them to the array
foreach ($folder in $userFolders) {
    #Write-Host $folder.Name
    $userFolderNames += $folder.Name
}

#display the array content
Write-Host "`Users found on $sourceComputer"
$userFolderNames


foreach ($UserName in $userFolderNames){
New-Item -Path "\\$destinationComputer\C$\Source\CP\" -type directory -Force
New-Item -Path "\\$destinationComputer\C$\Source\CP\$UserName" -type directory -Force
New-Item -Path "\\$destinationComputer\C$\Source\CP\$UserName\Desktop" -type directory -Force
New-Item -Path "\\$destinationComputer\C$\Source\CP\$UserName\Documents" -type directory -Force
New-Item -Path "\\$destinationComputer\C$\Source\CP\$UserName\Music" -type directory -Force
New-Item -Path "\\$destinationComputer\C$\Source\CP\$UserName\Videos" -type directory -Force
New-Item -Path "\\$destinationComputer\C$\Source\CP\$UserName\Favorites" -type directory -Force
New-Item -Path "\\$destinationComputer\C$\Source\CP\LogonScripts" -type directory -Force

    if (Test-Connection -ComputerName $destinationComputer, $sourceComputer -Count 1 -Quiet) {
        # Copy the file with new names to the remote folder
        Copy-Item -Path "\\$sourceComputer\C$\Users\$UserName\Desktop" -Destination "\\$destinationComputer\C$\Source\CP\$UserName\" -recurse -Force
        Copy-Item -Path "\\$sourceComputer\C$\Users\$UserName\Documents" -Destination "\\$destinationComputer\C$\Source\CP\$UserName\" -recurse -Force
        Copy-Item -Path "\\$sourceComputer\C$\Users\$UserName\Music" -Destination "\\$destinationComputer\C$\Source\CP\$UserName\" -recurse -Force
        Copy-Item -Path "\\$sourceComputer\C$\Users\$UserName\Videos" -Destination "\\$destinationComputer\C$\Source\CP\$UserName\" -recurse -Force
        Copy-Item -Path "\\$sourceComputer\C$\Users\$UserName\Favorites" -Destination "\\$destinationComputer\C$\Source\CP\$UserName\" -recurse -Force
$textInfo = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo
$inputString = $UserName
$capitalizedString = $textInfo.ToTitleCase($inputString.ToLower())

 $LogonScript = @"

' GetUsername
Option Explicit
Dim objNetwork, strUsername

' Create the WScript.Network object
Set objNetwork = CreateObject("WScript.Network")

' Get the username of the current logged-in user
strUsername = objNetwork.UserName

If strUsername = "$UserName" Then
Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

DocumentsPath = WshShell.SpecialFolders("MyDocuments")

Set OutFile = FSO.CreateTextFile("DocumentsPath.txt", True)
OutFile.WriteLine DocumentsPath
OutFile.Close
UserDocumentPath = " & DocumentsPath & vbCrLf & "

' CopyMultipleDirectoriesToMultipleTargets

Dim objFSO, sourceFolder, destFolder, i

Set objFSO = CreateObject("Scripting.FileSystemObject")

Dim oFSO
Set oFSO = CreateObject("Scripting.FileSystemObject")

' Create a new folder
'oFSO.CreateFolder "C:\Users\$UserName\Desktop"

' Define source folders and destination folders

Set sourceFolder = objFSO.GetFolder("C:\Source\CP\$UserName\Documents")
Set destFolder = objFSO.GetFolder("C:\Users\$UserName\Documents")
objFSO.CopyFolder sourceFolder.Path, destFolder.Path, True

Set sourceFolder = objFSO.GetFolder("C:\Source\CP\$UserName\Videos")
Set destFolder = objFSO.GetFolder("C:\Users\$UserName\Videos")
objFSO.CopyFolder sourceFolder.Path, destFolder.Path, True

Set sourceFolder = objFSO.GetFolder("C:\Source\CP\$UserName\Music")
Set destFolder = objFSO.GetFolder("C:\Users\$UserName\Music")
objFSO.CopyFolder sourceFolder.Path, destFolder.Path, True

Set sourceFolder = objFSO.GetFolder("C:\Source\CP\$UserName\Favorites")
Set destFolder = objFSO.GetFolder("C:\Users\$UserName\Favorites")
objFSO.CopyFolder sourceFolder.Path, destFolder.Path, True

'Set sourceFolder = objFSO.GetFolder("C:\Source\CP\$UserName\Desktop")
'Set destFolder = objFSO.GetFolder("C:\Users\$UserName\Desktop")
'objFSO.CopyFolder sourceFolder.Path, destFolder.Path, True

Set objFSO = Nothing
'Set oFso = CreateObject("Scripting.FileSystemObject") : oFso.DeleteFile Wscript.ScriptFullName, True
Else
Wscript.Quit
End If

' Clean up
Set objFSO = Nothing
Wscript.Quit

"@
        
        Add-Content -Path "\\$destinationComputer\C$\Source\CP\$UserName\$UserName-Config.vbs" -Value $LogonScript
        Add-Content -Path "\\$destinationComputer\C$\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\$UserName-Config.vbs" -Value $LogonScript
        Add-Content -Path "\\$destinationComputer\C$\Source\CP\LogonScripts\$UserName-Config.vbs" -Value $LogonScript
        Write-Host "successfully coppied $UserName to $destinationComputer" -ForegroundColor Green
        
    } else {
        Write-Host "Unable to reach $destinationComputer" -ForegroundColor Red
        Pause
    }
    Invoke-Item "\\$destinationComputer\c$\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
    #Invoke-Item "\\CNMODAM7025552\c$\Source\CP\LogonScripts"
    
}
       
