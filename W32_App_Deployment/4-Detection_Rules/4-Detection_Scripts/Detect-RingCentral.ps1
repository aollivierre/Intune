Try {
    if (Test-Path -Path "$($env:LOCALAPPDATA)\Programs\RingCentral\RingCentral.exe") {
        Write-Output "Ring Central is installed!"
        exit 0
    } else { 
        Write-Warning "Ring Central is not installed!"
        Exit -1
    }
    } catch [execption]{
    Write-Error "[Error] $($_.Exception.Message)"
    }