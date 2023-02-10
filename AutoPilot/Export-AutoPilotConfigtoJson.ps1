#need to grab script from S1E02 Intune Training on YouTube

#https://docs.microsoft.com/en-us/mem/autopilot/existing-devices#create-the-json-file

# Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-PackageProvider -Name NuGet -Force
Install-Module AzureAD -Force -allowclobber
Install-Module WindowsAutopilotIntune -Force -allowclobber
Install-Module Microsoft.Graph.Intune -Force -allowclobber



Connect-MSGraph


#Retrieve profiles in Autopilot for existing devices JSON format
Get-AutopilotProfile | ConvertTo-AutopilotConfigurationJSON





# Get-AutopilotProfile | ConvertTo-AutopilotConfigurationJSON
# {
#     "CloudAssignedTenantId": "1537de22-988c-4e93-b8a5-83890f34a69b",
#     "CloudAssignedForcedEnrollment": 1,
#     "Version": 2049,
#     "Comment_File": "Profile Autopilot Profile",
#     "CloudAssignedAadServerData": "{\"ZeroTouchConfig\":{\"CloudAssignedTenantUpn\":\"\",\"ForcedEnrollment\":1,\"CloudAssignedTenantDomain\":\"M365x373186.onmicrosoft.com\"}}",
#     "CloudAssignedTenantDomain": "M365x373186.onmicrosoft.com",
#     "CloudAssignedDomainJoinMethod": 0,
#     "CloudAssignedOobeConfig": 28,
#     "ZtdCorrelationId": "7F9E6025-1E13-45F3-BF82-A3E8C5B59EAC"
# }


# The Autopilot profile must be saved as a JSON file in ASCII or ANSI format. Windows PowerShell defaults to Unicode format. So, if you redirect output of the commands to a file, also specify the file format. For example, to save the file in ASCII format using Windows PowerShell, you can create a directory (ex: c:\Autopilot) and save the profile as shown below: (use the horizontal scroll bar at the bottom if needed to view the entire command string)


Get-AutopilotProfile | ConvertTo-AutopilotConfigurationJSON | Out-File "D:\Code\Intune\Intune\Autopilot\AutopilotConfigurationFile.json" -Encoding ASCII


#! IMPORTANT: The file name must be named AutopilotConfigurationFile.json and be encoded as ASCII/ANSI.


#todo After saving the file, move the file to a location suitable as a Microsoft Endpoint Configuration Manager package source.