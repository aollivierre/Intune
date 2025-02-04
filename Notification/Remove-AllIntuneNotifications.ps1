function Remove-AllIntuneNotifications {
    [CmdletBinding()]
    Param ()

    # Define the base URL for the Microsoft Graph endpoint to list all notification message templates
    $listNotificationTemplatesUrl = "https://graph.microsoft.com/beta/deviceManagement/notificationMessageTemplates"

    # Retrieve all notification message templates
    Write-Host "Retrieving all Intune notification message templates..."
    # $notificationTemplates = Invoke-MgGraphRequest -Method GET -Uri $listNotificationTemplatesUrl -All
    $notificationTemplates = Invoke-MgGraphRequest -Method GET -Uri $listNotificationTemplatesUrl

    if ($null -eq $notificationTemplates) {
        Write-Host "No notification message templates found or failed to retrieve them."
        return
    }

    # Iterate through each notification template and delete it
    foreach ($template in $notificationTemplates.value) {
        $deleteUrl = "$listNotificationTemplatesUrl/$($template.id)"
        
        # Perform the deletion
        Write-Host "Deleting notification message template: $($template.id)..."
        Invoke-MgGraphRequest -Method DELETE -Uri $deleteUrl

        Write-Host "Deleted notification message template: $($template.id)"
    }

    Write-Host "Completed deleting all Intune notification message templates."
}



# Remove-AllIntuneNotifications
