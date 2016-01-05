    Param(
      [Parameter(
         Mandatory=$false,
         Position=1
      )]
      [ValidateSet("backup","restore")]
 	  [string]$option=$(throw "Action param is required: backup, restore"),
 
      [Parameter(
         Mandatory=$false,
         Position=2
      )]
	  [ValidateSet("sdcard")]
	  [string]$sdcard
   )


$PROFILE_HOME = 'mozilla-profile'

adb shell stop b2g

switch ($option){
	"backup"{
		Write-Host "Doing a backup..."
		If (Test-Path $PROFILE_HOME){
			remove-item $PROFILE_HOME -recurse -force
		}


		mkdir $PROFILE_HOME\


		#Backup wifi
		mkdir $PROFILE_HOME\wifi
		adb pull /data/misc/wifi/wpa_supplicant.conf $PROFILE_HOME\wifi\wpa_supplicant.conf

		#Backup profile
		mkdir mozilla-profile\profile
		adb pull /data/b2g/mozilla $PROFILE_HOME\profile

		#Backup webapps
		mkdir mozilla-profile\data-local
		adb pull /data/local $PROFILE_HOME\data-local

		#Removing system apps
		$children = get-childitem $PROFILE_HOME\data-local\webapps\ -Filter *gaiamobile*
			foreach ($child in $children) {remove-item $children.fullname -recurse -ErrorAction SilentlyContinue}
		
		$children = get-childitem $PROFILE_HOME\data-local\webapps\ -Filter *marketplace*
			foreach ($child in $children) {remove-item $children.fullname -recurse -ErrorAction SilentlyContinue}
			
		if($sdcard -eq "sdcard"){
			mkdir $PROFILE_HOME\sdcard_backup
			adb pull /sdcard/ $PROFILE_HOME\sdcard_backup
		}
	}

	"restore"{
		Write-Host "Restoring a backup..."

		If (Test-Path $PROFILE_HOME){
			#Restore wifi
			adb push $PROFILE_HOME\wifi /data/misc/wifi
			adb shell chown wifi.wifi /data/misc/wifi/wpa_supplicant.conf

			#Restore profile
			adb push $PROFILE_HOME\profile /data/b2g/mozilla

			#Restore webapps
			adb push $PROFILE_HOME\data-local /data/local
		}else{
			throw "There is not any backup available"
		}


	}
}

#Done!
adb shell start b2g
& cmd /c pause
exit
