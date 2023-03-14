Set-Secret -Name "ClientSecret" -Secret 'g~08Q~h~CMnfGnTaG6CWg5hy.ttoZ9GZFnaYYdfN' -Metadata @{Description ='002 - Azure Key Vault - TeamViewer - Service Principal - PowerShell Automation - Client Secret.'}


Set-Secret -Name "ClientID" -Secret '4d80ad41-b02b-4465-9e60-a83e24fcd64f' -Metadata @{Description ='002 - Azure Key Vault - TeamViewer - Service Principal - PowerShell Automation - Client ID.'}

Set-Secret -Name "TenantID" -Secret 'dc3227a4-53ba-48f1-b54b-89936cd5ca53' -Metadata @{Description ='002 - Azure Key Vault - TeamViewer - Service Principal - PowerShell Automation - Tenant ID.'}




Set-Secret -Name "TeamViewer-Teams-Webhook" -Secret 'https://canadacomputing.webhook.office.com/webhookb2/55fe0bd5-5db4-4078-b922-005e7117f2ff@dc3227a4-53ba-48f1-b54b-89936cd5ca53/IncomingWebhook/120ed4936cb8422ca1ae604081f3fc0b/bf72cc2b-b88d-4570-afc6-dc785e5e5f80' -Metadata @{Description ='This is a webhook that posts to the #TeamViewer channel in CCI MS Teams.'}


Set-Secret -Name "TeamViewer-API_TOKEN_1" -Secret '7757967-7qRfr5r4Voq9MRxS7UKZ' -Metadata @{Description ='This is the API token for the TeamViewer host.'}


Set-Secret -Name "TeamViewer-CUSTOMCONFIG_ID_1" -Secret 'he26pyq' -Metadata @{Description ='This is the custom config ID for the TeamViewer host.'}

# $TeamViewerSecretName = "TeamViewer-CUSTOMCONFIG_ID_1"
# $CUSTOMCONFIG_ID_1 = 'he26pyq'

# $TeamViewerSecretName = "TeamViewer-API_TOKEN_1"
# $API_TOKEN_1 = '7757967-7qRfr5r4Voq9MRxS7UKZ'




