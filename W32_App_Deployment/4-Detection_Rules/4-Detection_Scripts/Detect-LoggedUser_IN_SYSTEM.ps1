Function Get-LoggedOnUserSID {
    # ref https://www.reddit.com/r/PowerShell/comments/7coamf/query_no_user_exists_for/
    $header=@('SESSIONNAME', 'USERNAME', 'ID', 'STATE', 'TYPE', 'DEVICE')
    $Sessions = query session
    [array]$ActiveSessions = $Sessions | Select -Skip 1 | Where {$_ -match "Active"}
    If ($ActiveSessions.Count -ge 1)
    {
        $LoggedOnUsers = @()
        $indexes = $header | ForEach-Object {($Sessions[0]).IndexOf(" $_")}        
        for($row=0; $row -lt $ActiveSessions.Count; $row++)
        {
            $obj=New-Object psobject
            for($i=0; $i -lt $header.Count; $i++)
            {
                $begin=$indexes[$i]
                $end=if($i -lt $header.Count-1) {$indexes[$i+1]} else {$ActiveSessions[$row].length}
                $obj | Add-Member NoteProperty $header[$i] ($ActiveSessions[$row].substring($begin, $end-$begin)).trim()
            }
            $LoggedOnUsers += $obj
        }
 
        $LoggedOnUser = $LoggedOnUsers[0]
        $LoggedOnUserSID = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\SessionData\$($LoggedOnUser.ID)" -Name LoggedOnUserSID -ErrorAction SilentlyContinue |
            Select -ExpandProperty LoggedOnUserSID
        Return $LoggedOnUserSID
    } 
}
 
$LoggedOnUserSID = Get-LoggedOnUserSID
 
If ($null -ne $LoggedOnUserSID)
{
    If ($null -eq (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue))
    {
        $null = New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
    }
    $i = Get-Item "HKU:\$LoggedOnUserSID\Software\<regkey>" -ErrorAction SilentlyContinue
    if ($null -eq $i)
    {
        # key doesn't exist, need to set
        "nada"
        Exit 1
    }
    else
    {
        $r = Get-ItemProperty "HKU:\$LoggedOnUserSID\Software\<regkey>" -Name '(Default)' -ErrorAction SilentlyContinue | 
            Select -ExpandProperty '(default)' 
        If ($r.Length -gt 0)
        {
            # default key is not correct value, need to update    
            "not right value"
            Exit 1
        }
        else
        {
            # all good
            "all good"
            Exit 0   
        }
    }
}
Else
{
    # no logged on user detected
    "no logged on user detected"
    Exit 1
}