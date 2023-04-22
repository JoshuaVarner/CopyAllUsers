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

Option Explicit
Dim objNetwork, strUsername

' Create the WScript.Network object
Set objNetwork = CreateObject("WScript.Network")

' Get the username of the current logged-in user
strUsername = objNetwork.UserName

If strUsername = "$UserName" Then

    Dim objShell, strDocumentsPath, strMusicPath, strVideosPath, strFavoritesPath, strRegKey

    Set objShell = CreateObject("WScript.Shell")

    strRegKey = "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders\"

    strDocumentsPath = objShell.RegRead(strRegKey & "Personal")
    strMusicPath = objShell.RegRead(strRegKey & "My Music")
    strVideosPath = objShell.RegRead(strRegKey & "My Video")
    strFavoritesPath = objShell.RegRead(strRegKey & "Favorites")

    Dim objFSO

    Set objFSO = CreateObject("Scripting.FileSystemObject")

    ' Replace the placeholders with your actual source and destination folder paths
    CopyFolderContents "C:\Source\CP\" & strUsername & "\Documents", strDocumentsPath
    CopyFolderContents "C:\Source\CP\" & strUsername & "\Music", strMusicPath
    CopyFolderContents "C:\Source\CP\" & strUsername & "\Videos", strVideosPath
    CopyFolderContents "C:\Source\CP\" & strUsername & "\Favorites", strFavoritesPath

    Sub CopyFolderContents(srcFolder, destFolder)
    If objFSO.FolderExists(srcFolder) And objFSO.FolderExists(destFolder) Then
        Dim objSrcFolder, objFile, objSubFolder

        Set objSrcFolder = objFSO.GetFolder(srcFolder)

        ' Copy all files
        For Each objFile In objSrcFolder.Files
            objFSO.CopyFile objFile.Path, destFolder & "\" & objFile.Name, True
        Next

        ' Copy all subfolders
        For Each objSubFolder In objSrcFolder.SubFolders
            objFSO.CopyFolder objSubFolder.Path, destFolder & "\" & objSubFolder.Name, True
        Next

        'WScript.Echo "Successfully copied files from " & srcFolder & " to " & destFolder
    ElseIf Not objFSO.FolderExists(srcFolder) Then
        'WScript.Echo "Source folder not found: " & srcFolder
        WScript.Quit
    ElseIf Not objFSO.FolderExists(destFolder) Then
        'WScript.Echo "Destination folder not found: " & destFolder
        WScript.Quit
    End If
End Sub
Else
    WScript.Quit
End If

Set objNetwork = Nothing
Set objShell = Nothing
Set objFSO = Nothing

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
       
