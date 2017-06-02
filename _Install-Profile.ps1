$profileFolder = $PROFILE.Substring(0,$PROFILE.LastIndexOf("\"))
new-item $profileFolder
New-Item $profile
new-item $profileFolder"\Transscripts" -ItemType Directory