#Variables
$SiteURL = "https://crescent.sharepoint.com"
$FilesPath = "C:\Upload"
$ServerRelativePath = "/Shared Documents"
 
#Connect to PnP Online
Connect-PnPOnline -Url $SiteURL -Credentials (Get-Credential)
 
#Get All Files from a Local Folder
$Files = Get-ChildItem -Path $FilesPath -Force -Recurse
 
#bulk upload files to sharepoint online using powershell
ForEach ($File in $Files)
{
    Write-host "Uploading $($File.Directory)\$($File.Name)"
  
    #upload a file to sharepoint online using powershell - Upload File and Set Metadata
    Add-PnPFile -Path "$($File.Directory)\$($File.Name)" -Folder $ServerRelativePath -Values @{"Title" = $($File.Name)}
}
