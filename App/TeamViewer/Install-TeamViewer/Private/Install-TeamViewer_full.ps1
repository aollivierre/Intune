$TEAMVIEWER_HOST_MSI = $null
$TEAMVIEWER_HOST_MSI = "$PSSCRIPTROOT\bin\TeamViewerMSI\full\TeamViewer_full.msi"


# $CUSTOMCONFIG_ID = $null
# $CUSTOMCONFIG_ID = 'he26pyq'

# $API_TOKEN = $null
# $API_TOKEN = '7757967-7qRfr5r4Voq9MRxS7UKZ'

# $TargetMachineName = $null
# $TargetMachineName = [System.Environment]::MachineName

# $TVGROUPNAME = $null
# $TVGROUPNAME = '""Cohen Centre""' #! this name should not contain any spaces for it to work with msiexecs

$Options = $null
$cmdArgs = $null

# $date = ""
# $date = [System.DateTime]::Now.ToString("yyyy%M%d")

# $logdir = ""
# $logdir = "$PSSCRIPTROOT\msilogs"
# if (!(Test-Path -Path $logdir )) { 
#     New-Item -ItemType directory -Path $logdir
# } 

# $Logfile = ""
# $Logfile = "$($logdir)\MSI_Log_$($date)_$($TargetMachineName).log"

# $what = @(
    # '/i'
# )

$options = @(
    '/i'
    "$TEAMVIEWER_HOST_MSI"
    '/qn'
    # "CUSTOMCONFIGID=$CUSTOMCONFIG_ID"
    # "APITOKEN=$API_TOKEN"
    # "/L*V"
    # "$Logfile"
    # '/promptrestart'
    # 'ASSIGNMENTOPTIONS="--grant-easy-access"'
    # "ASSIGNMENTOPTIONS="--alias=""$TargetMachineName""""
    # 'ASSIGNMENTOPTIONS="--reassign"'
    # 'ASSIGNMENTOPTIONS="--group=""Cohen Centre"""' ##! Change this
)

$cmdArgs = @(
    $options
)

msiexec.exe @cmdArgs

#!no need to uninstall just need to re run the msiexec with /i command

# $TEAMVIEWER_HOST_MSI = $null
# $TEAMVIEWER_HOST_MSI = 'C:\Users\Abdullah\GitHub\Git-HubRepositry\Tools\TeamViewerMSI\Host\TeamViewer_Host.msi'
# msiexec.exe /x $TEAMVIEWER_HOST_MSI /qn /L*V $Logfile

# msiexec.exe /uninstall $TEAMVIEWER_HOST_MSI /qn

#! if the computer is already added to team viewer ensure that your delete the computer before running this script again