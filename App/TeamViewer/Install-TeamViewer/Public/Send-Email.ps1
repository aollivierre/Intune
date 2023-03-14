# Set ScripRoot variable to the path which the script is executed from
$ScriptRoot5 = $null
$ScriptRoot5 = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}
function Send-Email($emailbody_2, $log_2) {
  
    begin {

        #Create the SMTP Parameters
        $emailFrom_2 = $null
        # $emailFrom_2 = "websiteSMTP@canadacomputing.ca"
        $emailFrom_2 = "alerts@canadacomputing.ca"
        
        $emailTo_2 = $null
        $emailTo_2 = 'Support@canadacomputing.ca'
        
        $Subject_2 = $null
        $Subject_2 = "Your TeamViewer is now Installed - Your TeamViewer ID is now provided"
        
        $Body_2 = $null
        $Body_2 = $emailbody_2
        
        $smtp_2Server = $null
        $smtp_2Server = "smtp.office365.com"
        
        $smtp_2Port = $null
        $smtp_2Port = "587"
        
        #Create the SMTP client
        $smtp_2 = $null
        $smtp_2 = New-Object System.Net.Mail.SmtpClient($smtp_2Server, $smtp_2Port)

        #Create the Message
        $message_2 = $null
        $message_2 = new-object System.Net.Mail.MailMessage 
        $message_2.From = $EmailFrom_2 
        $message_2.To.Add($EmailTo_2)
        $message_2.IsBodyHtml = $True 
        $message_2.Subject = $Subject_2 
        $message_2.body = $body_2 


        #Create the Encryption Keys parameters
        $Password_File_2 = $null
        $Key_File_2 = $null
        $Key_2 = $null
        $MyCredential_2 = $null

        $User_2 = $null
        # $User_2 = "websiteSMTP@canadacomputing.ca"
        $User_2 = "alerts@canadacomputing.ca"
        $Password_File_2 = "$ScriptRoot5\Password.txt"
        $Key_File_2 = "$ScriptRoot5\AES.key"
        $Key_2 = Get-Content $Key_File_2

        $SecurePWD_2 = $null
        $SecurePWD_2 = (Get-Content $Password_File_2 | ConvertTo-SecureString -Key $Key_2)
        $MyCredential_2 = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User_2, $SecurePWD_2

        $Password_OBJECT_2 = $null
        $Password_OBJECT_2 = $MyCredential_2.GetNetworkCredential().Password
           
    }
        
    process {

        try {

            # Create the attach object

            $ScriptRoot5Dir = $null
            $ScriptRoot5Dir = $ScriptRoot5.Replace("Cmdlet", "")

            # $DBG

            $Log_Folder_Dir_5 = $null
            $Log_Folder_Dir_5 = "$ScriptRoot5Dir\logs"

            # $Multilple_files_5 = $null
            # $Multilple_files_5 = Get-ChildItem $Log_Folder_Dir_5
        
            $Multilple_files_5 = $null
            $Multilple_files_5 = Get-ChildItem "$Log_Folder_Dir_5"
            # $Multilple_files_5
     
        
            foreach ($single_File_5 in ($Multilple_files_5)) {

                $attachment_2 = $null
                $attachment_2 = New-Object System.Net.Mail.Attachment -ArgumentList "$Log_Folder_Dir_5\$single_File_5"
                # $attachment_2.Dispose()
                $message_2.Attachments.Add($attachment_2)
            }

            $smtp_2.EnableSsl = $true
            $smtp_2.Credentials = New-Object System.Net.NetworkCredential($MyCredential_2.UserName, $Password_OBJECT_2)
            $smtp_2.Send($message_2)
                
        }
        catch [Exception] {
        
            Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            # Write-Host $PSItem -ForegroundColor Red
            $PSItem
            Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red
            
            
            $ErrorMessage_2 = $_.Exception.Message
            write-host $ErrorMessage_2  -ForegroundColor Red
            Write-Output "Ran into an issue: $PSItem"
            Write-host "Ran into an issue: $PSItem" -ForegroundColor Red
            throw "Ran into an issue: $PSItem"
            throw "I am the catch"
            throw "Ran into an issue: $PSItem"
            $PSItem | Write-host -ForegroundColor
            $PSItem | Select-Object *
            $PSCmdlet.ThrowTerminatingError($PSitem)
            throw
            throw "Something went wrong"
            Write-Log $PSItem.ToString()
            
        }
        finally {

            $attachment_2.Dispose()
        }
    }
        
    end {
            
    }
}

#usage
#Send-Email -emailbody "Hello World" -log "C:\CCI\Install-TeamViewer\Unrestricted_PS_Execution_Policy.pol"
#Send-Email -emailbody "$variable"
#Send-Email -emailbody "Hello World" -log "C:\CCI\New Text Document.txt"
# Send-Email -emailbody "Hello World"




#For testing purposes
# $range = 1..15

# foreach ($item in $range) {

#     Start-Sleep 60
#     Send-Email -emailbody "Hello World"
# }

# # Send-Email -emailbody "Hello World"
