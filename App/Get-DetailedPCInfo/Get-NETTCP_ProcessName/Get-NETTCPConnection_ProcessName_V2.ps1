function Get-NETTCPConnection_ProcessName {

    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $ExportFilePath
    )


    #PowerNetstat below

    $OBJECT_ARRAY = $null
    $MULTIPLE_TCP_CONNECTIONS = $null
    $MULTIPLE_TCP_CONNECTIONS = Get-NetTCPConnection | Select-Object -Property State, OwningProcess, LocalAddress, LocalPort, RemoteAddress, RemotePort, AppliedSetting
    [Hashtable]$Processes = @{ }

    # Make a lookup table by process ID
    $MULTIPLE_PROCESS_LIST = $null
    # Make a lookup table by process ID
    $MULTIPLE_PROCESS_LIST = $null
    $MULTIPLE_PROCESS_LIST = Get-Process | Select-Object -Property Id, ProcessName, Product, Description, Path, Company, FileVersion

    #the following requires elevation and will return the following error without elevation
#     Get-Process : The 'IncludeUserName' parameter requires elevated user rights. Try running the command again in a session that has been opened with
# elevated user rights (that is, Run as Administrator).
# At line:1 char:1
# + Get-Process -IncludeUserName | Select-Object -Property Id, ProcessNam ...
# + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#     + CategoryInfo          : InvalidOperation: (:) [Get-Process], InvalidOperationException
#     + FullyQualifiedErrorId : IncludeUserNameRequiresElevation,Microsoft.PowerShell.Commands.GetProcessCommand
    # $MULTIPLE_PROCESS_LIST = Get-Process -IncludeUserName | Select-Object -Property Id, ProcessName, Product, Description, Path, Company, FileVersion, UserName

    foreach ($SINGLE_PROCESS_LIST in $MULTIPLE_PROCESS_LIST) {
        $Processes[$SINGLE_PROCESS_LIST.Id] = $SINGLE_PROCESS_LIST
    }

    $OBJECT_ARRAY = foreach ($SINGLE_TCP_CONNECTIONS in $MULTIPLE_TCP_CONNECTIONS) {
    
        [PSCustomObject]@{
    
            State          = $SINGLE_TCP_CONNECTIONS.State
            LocalAddress   = $SINGLE_TCP_CONNECTIONS.LocalAddress
            LocalPort      = $SINGLE_TCP_CONNECTIONS.LocalPort
            RemoteAddress  = $SINGLE_TCP_CONNECTIONS.RemoteAddress
            RemotePort     = $SINGLE_TCP_CONNECTIONS.RemotePort
            AppliedSetting = $SINGLE_TCP_CONNECTIONS.AppliedSetting
            PID            = $SINGLE_TCP_CONNECTIONS.OwningProcess
            ProcessName    = $Processes[[int]$SINGLE_TCP_CONNECTIONS.OwningProcess].ProcessName
            Product        = $Processes[[int]$SINGLE_TCP_CONNECTIONS.OwningProcess].Product
            Description    = $Processes[[int]$SINGLE_TCP_CONNECTIONS.OwningProcess].Description
            Path           = $Processes[[int]$SINGLE_TCP_CONNECTIONS.OwningProcess].Path
            Company        = $Processes[[int]$SINGLE_TCP_CONNECTIONS.OwningProcess].Company
            FileVersion    = $Processes[[int]$SINGLE_TCP_CONNECTIONS.OwningProcess].FileVersion
            # UserName       = $Processes[[int]$SINGLE_TCP_CONNECTIONS.OwningProcess].UserName
        }
    }
    $OBJECT_ARRAY | Sort-Object -Property ProcessName, UserName | export-csv $ExportFilePath
    
}


# #example
# $ExportFilePath = 'c:\cci\processes.csv'
# Get-NETTCPConnection_ProcessName -ExportFilePath $ExportFilePath


# Read-Host -prompt 'I am done'