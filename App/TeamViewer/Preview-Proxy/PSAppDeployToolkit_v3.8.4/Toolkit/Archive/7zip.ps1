$ErrorActionPreference = "SilentlyContinue"
# Set ScripRoot variable to the path which the script is executed from
$7zipScriptRoot1 = $null
$7zipScriptRoot1 = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}

        $AppDeployToolkit = "$7zipScriptRoot1\AppDeployToolkit"
		$PSScripts_1 = @( Get-ChildItem -Path $AppDeployToolkit\*.ps1 -Recurse -ErrorAction SilentlyContinue )			
		#Dot source the files
		Foreach ($import in @($PSScripts_1)) {
			Try {
	
				Write-host "processing $import"
				#         $files = Get-ChildItem -Path $root -Filter *.ps1
				. $import.fullname
			}
			Catch {
				Write-Error -Message "Failed to import function $($import.fullname): $_"
			}
		}



		$zipFilePassword = "welcome123"
		$zipfile = "C:\cci\scripts\package\1beccd4e-60a8-40bf-9c5b-55d107924e45\toolkit.zip"
		Execute-Process -Path "C:\Program Files\7-Zip\7z.exe" -Parameters "e -oe:\ -y -tzip -p$zipFilePassword $zipFile" -WindowStyle Hidden