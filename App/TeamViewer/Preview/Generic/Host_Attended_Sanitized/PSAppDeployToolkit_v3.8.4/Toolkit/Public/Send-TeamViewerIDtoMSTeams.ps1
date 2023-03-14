. "$PSScriptRoot\get-Deviceinfo.ps1"


<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>



#we need to bring in some new modules one for cred management and one for MS Teams integration
#the idea is to avoid using e-mail and instead using MS Teams or Slack
#the client ID/Client secret will be even more secure this way because in the MS Graph mailer using MailoZ we are restricting client/app to only send mail
#but 

#if the zip file password is compromised then the cred manager can be compromised because the decryptor is included and can be tweaked to provide the secrets in plain text
#even if the cred manager is not compromised the attacker can still send emails just by running the script wthout knowing the decryptor mechanism or knowing the secrets
#because again the decryptor is included within the package
#so we need a secure way to manage creds and then give this client/app permissions to only send to an internal MS Teams so even in the case of a compromise the attack is contained and is only allowed to send to an MS Team






<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>


# $LoadModuleFileScriptRoot_1 = $null
# $LoadModuleFileScriptRoot_1 = if ($PSVersionTable.PSVersion.Major -lt 3) {
#     Split-Path -Path $MyInvocation.MyCommand.Path
# }
# else {
#     $PSScriptRoot
# }

function Send-TeamViewerIDtoMSTeams {
    [CmdletBinding()]
    param (
        [Parameter()]
        $TeamViewerSecret,
        $TeamViewerID,
        $Deviceinfo
    )
        
    begin {
    

        # $date = [System.DateTime]::Now.ToString("yyyy_MM_dd_HH_mm_ss")
        $date = Get-Date -Format F

    }
        
    process {


        try {



            # Install-PackageProvider -Name NuGet -Force:$true

            # Install-Module -Name PSTeams -Force:$true


            # Clear-Host
            # Import-Module PSTeams

            # $TeamsID = 'https://outlook.office.com/webhook/a5c7c95a....'
            # $TeamsID = 'Fill in your Teams Channel Web hook connector URI here'

            # $TeamsID = Get-Secret -Name "TeamViewer-Teams-Webhook"
            $TeamsID = $TeamViewerSecret

            $Color = 'Chocolate'

            $Button1 = New-TeamsButton -Name 'Visit Canada Computing Website' -Link "https://CanadaComputing.ca/support"
            $Button2 = New-TeamsButton -Name 'Visit TeamViewer Website' -Link "https://login.teamviewer.com/"

            $Fact1 = New-TeamsFact -Name 'Bold' -Value '**Thank you for using the TeamViewer Script v1.0**'
            $Fact2 = New-TeamsFact -Name 'Italic and Bold' -Value '***Italic and Bold value***'
            # $Fact3 = New-TeamsFact -Name 'Italic' -Value 'Date with italic *2010-10-10*'
            # $Fact3 = New-TeamsFact -Name 'TeamViewer ID:' -Value "$TeamViewer_Client_ID_1"
            $Fact3 = New-TeamsFact -Name 'TeamViewer ID:' -Value "$TeamViewerID"

            $Fact13 = New-TeamsFact -Name 'Device Hostname:' -Value ($Deviceinfo).Hostname
            $Fact14 = New-TeamsFact -Name 'Device FQDN:' -Value ($Deviceinfo).FQDN
            $Fact15 = New-TeamsFact -Name 'Device PrivateIP:' -Value ($Deviceinfo).PrivateIP
            $Fact16 = New-TeamsFact -Name 'Device PublicIP:' -Value ($Deviceinfo).publicIP
            $Fact17 = New-TeamsFact -Name 'Device OS:' -Value ($Deviceinfo).OS
            $Fact18 = New-TeamsFact -Name 'Device SerialNumber:' -Value ($Deviceinfo).SerialNumber
            $Fact19 = New-TeamsFact -Name 'Device Manufacturer:' -Value ($Deviceinfo).Manufacturer
            $Fact20 = New-TeamsFact -Name 'Device Model:' -Value ($Deviceinfo).Model
            $Fact21 = New-TeamsFact -Name 'Device User:' -Value ($Deviceinfo).User


            $Fact4 = New-TeamsFact -Name 'Website' -Value "[Canada Computing](http://assist.canadacomputing.ca)"
            $Fact5 = New-TeamsFact -Name 'Other link example' -Value "[Evotec](https://evotec.xyz) and some **bold** text"
            $Fact6 = New-TeamsFact -Name 'This is how list looks like' -Value "
* hello
    * 2010-10-10
* test
    * another
* test
* hello"
            $Fact7 = New-TeamsFact -Name 'This is strike through example' -Value "<strike> This is strike-through </strike>"
            $Fact8 = New-TeamsFact -Name 'List example with nested list' -Value "
- One value
- Another value
    - Third value
        - Fourth value
"
            $Fact9 = New-TeamsFact -Name 'List example with a twist' -Value "
1. First ordered list item
2. Another item
* Unordered sub-list.
1. Actual numbers don't matter, just that it's a number
    1. Ordered sub-list
    2. Another entry
4. And another item.
"

            $Fact10 = New-TeamsFact -Name 'Code highlight' -Value "This is ``showing code highlight`` "
            $Fact11 = New-TeamsFact -Name '' -Value "

### As you see I've not added Name at all for this one and it merges a bit with Fact 10

This is going to add horizontal line below. While this line is highlighed.

---

And a block quote
> Block quote

# H1
## H2
### H3
#### H4
##### H5
###### H6

"


            # $Section1 = New-TeamsSection `
                # -ActivityTitle "**Przemyslaw Klys**" `
                # -Buttons $Button1, $Button2 `
                # -ActivityDetails $Fact1
                # -ActivitySubtitle "@przemyslawklys - 9/12/2016 at 5:33pm" `
                # -ActivityImageLink "https://pbs.twimg.com/profile_images/1017741651584970753/hGsbJo-o_400x400.jpg" `
                # -ActivityText "Climate change explained in comic book form by xkcd xkcd.com/1732" `
               
                # -ActivityDetails $Fact1, $Fact2

            $Section2 = New-TeamsSection `
                -ActivityTitle "**TeamViewer has been installed - Connection Details below**" `
                -ActivitySubtitle "Installed on $date " `
                -ActivityImageLink "https://static.teamviewer.com/resources/2019/07/TeamViewer_Logo_512x512.png" `
                -ActivityText "Remember: Login to Teamviewer and move this new device to the proper TeamViewer group and save the unattended password and name it with an alias" `
                -ActivityDetails $Fact3, $Fact13, $Fact14, $Fact15, $Fact16, $Fact17, $Fact18, $Fact19, $Fact20, $Fact21 `
                -Buttons $Button1, $Button2 `
                # -Buttons $Button1 `

                
                # -ActivityDetails $Fact3, $Fact13, $Fact14, $Fact15, $Fact16, $Fact17, $Fact18, $Fact19, $Fact20, $Fact21, $Fact4, $Fact5, $Fact6, $Fact7, $Fact8, $Fact9, $Fact10, $Fact11
                # -ActivityDetails $Fact3, $Fact4, $Fact5, $Fact6, $Fact7, $Fact8, $Fact9, $Fact10, $Fact11
               

            # $Section3 = New-TeamsSection `
            #     -ActivityTitle "**Przemyslaw Klys**" `
            #     -ActivitySubtitle "@przemyslawklys - 9/12/2016 at 5:33pm" `
            #     -ActivityImage Add `
            #     -ActivityText "Climate change explained in comic book form by xkcd xkcd.com/1732" `
            #     -Buttons $Button1 `
            #     -ActivityDetails $Fact3, $Fact4, $Fact5, $Fact6, $Fact7, $Fact8, $Fact9, $Fact10, $Fact11

            Send-TeamsMessage `
                -URI $TeamsID `
                -MessageTitle 'TeamViewer Remote Access Deployement' `
                -MessageText 'Source: https://Assist.canadacomputing.ca' `
                -Color Chocolate `
                -Sections $Section2
                # -Sections $Section2, $Section1

            # Send-TeamsMessage `
            #     -URI $TeamsID `
            #     -MessageTitle 'Message Title' `
            #     -MessageText 'This is text' `
            #     -Color Chocolate `
            #     -Sections $Section3


        }
           
        <#Do this if a terminating exception happens#>


        catch [Exception] {
        
            Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            # Write-Host $PSItem -ForegroundColor Red
            $PSItem
            Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red
                    
                    
            $ErrorMessage_3 = $_.Exception.Message
            write-host $ErrorMessage_3  -ForegroundColor Red
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
            $PSCmdlet.WriteError($_)
                


        }
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
        }
            
    }
        
    end {
            
    }
}

# $Deviceinfo_Object = get-deviceinfo

# # Send-TeamViewerIDtoMSTeams -TeamViewerSecret $TeamViewerSecret_1_Webhook_URI_Value -TeamViewerID $TeamViewerID_1
# Send-TeamViewerIDtoMSTeams -TeamViewerSecret "https://canadacomputing.webhook.office.com/webhookb2/55fe0bd5-5db4-4078-b922-005e7117f2ff@dc3227a4-53ba-48f1-b54b-89936cd5ca53/IncomingWebhook/120ed4936cb8422ca1ae604081f3fc0b/bf72cc2b-b88d-4570-afc6-dc785e5e5f80" -TeamViewerID "777111555" -Deviceinfo $Deviceinfo_Object



