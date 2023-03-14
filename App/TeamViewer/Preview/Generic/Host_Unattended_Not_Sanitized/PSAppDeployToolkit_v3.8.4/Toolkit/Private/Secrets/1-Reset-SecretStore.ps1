#The sectore store comes before the secret vault

#reset the secret store before starting new secret store and new secret vaults
Reset-SecretStore -Scope CurrentUser -Authentication Password -PasswordTimeout (60*60) -Interaction None -Confirm:$false -Force:$true