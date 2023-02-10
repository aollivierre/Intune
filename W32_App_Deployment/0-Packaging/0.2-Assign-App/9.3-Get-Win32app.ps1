<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.


    https://github.com/MSEndpointMgr/IntuneWin32App#module-dependencies
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines


    expected output


    VERBOSE: Current authentication token expires in (minutes): 2
VERBOSE: Querying for all Win32 apps
VERBOSE: GET https://graph.microsoft.com/Beta/deviceAppManagement/mobileApps?$filter=isof('microsoft.graph.win32LobApp')
VERBOSE: Querying explicitly to retrieve all properties for Win32 app with ID: 0c7536cc-e556-431c-a6fc-77f6345b1a78
VERBOSE: GET https://graph.microsoft.com/Beta/deviceAppManagement/mobileApps/0c7536cc-e556-431c-a6fc-77f6345b1a78


@odata.context                  : https://graph.microsoft.com/beta/$metadata#deviceAppManagement/mobileApps/$entity
@odata.type                     : #microsoft.graph.win32LobApp
id                              : 0c7536cc-e556-431c-a6fc-77f6345b1a78
displayName                     : AgentSetup_FGC_Corporate.exe
description                     : Description
publisher                       : Publisher
largeIcon                       :
createdDateTime                 : 2022-07-23T23:54:21.5418051Z
lastModifiedDateTime            : 2022-07-23T23:54:21.5418051Z
isFeatured                      : False
privacyInformationUrl           :
informationUrl                  :
owner                           :
developer                       :
notes                           :
uploadState                     : 1
publishingState                 : published
isAssigned                      : False
roleScopeTagIds                 : {0}
dependentAppCount               : 0
supersedingAppCount             : 0
supersededAppCount              : 0
committedContentVersion         : 1
fileName                        : IntunePackage.intunewin
size                            : 10468320
installCommandLine              : powershell.exe .\install.ps1
uninstallCommandLine            : powershell.exe .\uninstall.ps1
applicableArchitectures         : x86,x64
minimumFreeDiskSpaceInMB        :
minimumMemoryInMB               :
minimumNumberOfProcessors       :
minimumCpuSpeedInMHz            : 
msiInformation                  :
setupFilePath                   : AgentSetup_FGC_Corporate.exe
minimumSupportedWindowsRelease  : 1607
displayVersion                  :
allowAvailableUninstall         : False
minimumSupportedOperatingSystem : @{v8_0=False; v8_1=False; v10_0=False; v10_1607=True; v10_1703=False; v10_1709=False; v10_1803=False; v10_1809=False; v10_1903=False;
                                  v10_1909=False; v10_2004=False; v10_2H20=False; v10_21H1=False}
detectionRules                  : {@{@odata.type=#microsoft.graph.win32LobAppFileSystemDetection; path=C:\Program Files\Application; fileOrFolderName=application.exe;
                                  check32BitOn64System=False; detectionType=exists; operator=notConfigured; detectionValue=},
                                  @{@odata.type=#microsoft.graph.win32LobAppRegistryDetection; check32BitOn64System=True; keyPath=HKEY_LOCAL_MACHINE\SOFTWARE\Program;
                                  valueName=; detectionType=exists; operator=notConfigured; detectionValue=}}
requirementRules                : {}
rules                           : {@{@odata.type=#microsoft.graph.win32LobAppFileSystemRule; ruleType=detection; path=C:\Program Files\Application;
                                  fileOrFolderName=application.exe; check32BitOn64System=False; operationType=exists; operator=notConfigured; comparisonValue=},
                                  @{@odata.type=#microsoft.graph.win32LobAppRegistryRule; ruleType=detection; check32BitOn64System=True;
                                  keyPath=HKEY_LOCAL_MACHINE\SOFTWARE\Program; valueName=; operationType=exists; operator=notConfigured; comparisonValue=}}
installExperience               : @{runAsAccount=system; deviceRestartBehavior=basedOnReturnCode}
returnCodes                     : {@{returnCode=0; type=success}, @{returnCode=1707; type=success}, @{returnCode=3010; type=softReboot}, @{returnCode=1641;
                                  type=hardReboot}...}
#>



# Get all Win32 apps
Get-IntuneWin32App -Verbose

# Get a specific Win32 app by it's display name
Get-IntuneWin32App -DisplayName "7-zip" -Verbose

# Get a specific Win32 app by it's id
Get-IntuneWin32App -ID "<Win32 app ID>" -Verbose