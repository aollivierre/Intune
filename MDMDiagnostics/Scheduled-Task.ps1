-ExecutionPolicy Bypass -File \\cpha-fs1\MDMDiagnostics\IntuneODCStandAlone.ps1



-ExecutionPolicy Bypass -File \\cpha-fs1\MDMDiagnostics\FixHAADJPendingReg.ps1
-ExecutionPolicy Bypass -File \\192.168.20.43\MDMDiagnostics\FixHAADJPendingReg_LITE.ps1

-ExecutionPolicy Bypass -File \\cpha-fs1\MDMDiagnostics\EnrollMDM.ps1
-ExecutionPolicy Bypass -File \\192.168.20.43\MDMDiagnostics\EnrollMDM.ps1