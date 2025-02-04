For the Windows Autopilot device registration script to work properly with Intune, you'll need to assign the following Microsoft Graph API permissions to your app registration in Entra ID (formerly Azure AD):

Required Graph API permissions:
1. `DeviceManagementServiceConfig.ReadWrite.All` - This allows the app to read and write Windows Autopilot deployment configuration
2. `Device.ReadWrite.All` - Allows creation and modification of device objects in Entra ID
3. `DeviceManagementManagedDevices.ReadWrite.All` - Required for enrollment status tracking and policy assignments

Optional permissions (depending on your scenario):
4. `Group.ReadWrite.All` - Only needed if assigning devices to Azure AD groups during registration
5. `Domain.ReadWrite.All` - Only needed for hybrid Entra ID join deployments

Steps to assign these permissions:
1. Go to Entra ID (Azure AD) portal
2. Navigate to App Registrations
3. Select your application
4. Click on "API Permissions" in the left menu
5. Click "Add a permission"
6. Choose "Microsoft Graph"
7. Select "Application permissions"
8. Add each of the permissions listed above
9. After adding the permissions, click the "Grant admin consent" button

Important notes:
- These permissions are Application-level permissions (not Delegated)
- An admin needs to grant consent for these permissions
- Make sure your app has a client secret generated and valid
- The account used to grant admin consent must be a Global Administrator
- Entra ID P1/P2 License is required for Autopilot functionality
- Auto-enrollment must be enabled in Entra ID > Mobility (MDM) > Microsoft Intune

These permissions will allow the script to:
- Read and write device information
- Upload device information to Windows Autopilot
- Manage Autopilot deployment profiles and settings
- Handle device enrollment and policy assignments
