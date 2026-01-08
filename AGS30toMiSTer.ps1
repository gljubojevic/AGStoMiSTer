# variables and definitions
$AmigaFiles = ".\AmigaFiles"
$FunctionsFolder = '.\Functions\'
$ToolsFolder = '.\Tools\'
$BuildFolder = '.\Build\'
#$BuildFolder = 'C:\Log\'
$BuildRoot = "$($BuildFolder)games\AmigaGameSelector30\"
$BuildHDD = "$($BuildRoot)HDD\"

# HST-Imager
$HSTImagerDownload = "https://github.com/henrikstengaard/hst-imager/releases/download/1.4.526/hst-imager_v1.4.526-e74dd1a_console_windows_x64.zip"
$HSTImagerPath = "$($ToolsFolder)hst-imager.zip"
$HSTImager = "$($ToolsFolder)hst-imager\"
$HSTImagerExe = "$($ToolsFolder)hst-imager\hst.imager.exe"

# AHI
$AHIDownload = "https://aminet.net/driver/audio/ahiusr_4.18.lha"
$AHIPath = "$($ToolsFolder)ahiusr_4.18.lha"

# Load all functions
Get-ChildItem -Path $FunctionsFolder -Recurse | Where-Object { $_.PSIsContainer -eq $false } | ForEach-Object {
    . ($_).fullname
}

# Main code
Write-Host "Starting ..."

##################################################
# HST-Imager download and extract
if ((Confirm-FileExists -PathToCheck $HSTImagerPath) -eq $false){
	$ok = Get-DownloadFile -DownloadURL $HSTImagerDownload -OutputLocation $HSTImagerPath -NumberOfAttempts 2
	if ($ok -eq $false) {
		throw "Download of $($HSTImagerDownload) failed"
	}
}
if ((Test-Path $HSTImager) -eq $false) {
	Expand-Archive -LiteralPath $HSTImagerPath -DestinationPath $HSTImager
}


##################################################
# AHI download
if ((Confirm-FileExists -PathToCheck $AHIPath) -eq $false){
	$ok = Get-DownloadFile -DownloadURL $AHIDownload -OutputLocation $AHIPath -NumberOfAttempts 2
	if ($ok -eq $false) {
		throw "Download of $($AHIDownload) failed"
	}
}


# Hardcode images position
#$AGS30hdf = "E:\Download\AGS_UAE\AGS_UAE_v30\WinUAE\AGS_UAE"
##################################################
# Select folder with AGS UAE HD files
if (-not $AGS30hdf) {
	$AGS30hdf = FolderBrowserDialog "Select folder with AGS UAE 3.0 HDF files" $currentPath
}
if ($null -eq $AGS30hdf) {
	throw "AGS UAE 3.0 folder with HDF files not selected"
}
# check for all HDF files							Original   CopyTo   
FileRequired -path "$($AGS30hdf)\Workbench.hdf"		# DH0	-> DH0
FileRequired -path "$($AGS30hdf)\Work.hdf"			# DH3	-> DH1
FileRequired -path "$($AGS30hdf)\Music.hdf"			# DH2	-> DH2
FileRequired -path "$($AGS30hdf)\Media.hdf"			# DH3!!	-> DH3
FileRequired -path "$($AGS30hdf)\AGS_Drive.hdf"		# DH4	-> DH4
FileRequired -path "$($AGS30hdf)\Games.hdf"			# DH5	-> DH5
FileRequired -path "$($AGS30hdf)\Premium.hdf"		# DH6	-> DH6
FileRequired -path "$($AGS30hdf)\Emulators.hdf"		# DH7	-> DH7
FileRequired -path "$($AGS30hdf)\Emulators2.hdf"	# DH0!!	-> DH8
FileRequired -path "$($AGS30hdf)\WHD_Games.hdf"		# DH9	-> DH9
FileRequired -path "$($AGS30hdf)\WHD_Demos.hdf"		# DH10	-> DH10


##################################################
# Create HDD image
$AGS30MiSTerHDD = "$($BuildHDD)AGS30MiSTer.hdf"
# HDD image Size: 600MB + 1.2GB + 3.5GB + 2.8GB + 3.5GB + 6.3GB + 7.8GB + 2.7GB + 5.2gb + 7.5gb + 1.4gb + 3.952MB (Partition table)
$AGS30MiSTerHDDSize = (MBtoBytes 600) + (MBtoBytes 1200) + (MBtoBytes 3500) + (MBtoBytes 2800) + (MBtoBytes 3500) + (MBtoBytes 6300) + (MBtoBytes 7800) + (MBtoBytes 2700) + (MBtoBytes 5200) + (MBtoBytes 7500) + (MBtoBytes 1400) + (KBtoBytes 4432)

if (Test-Path $AGS30MiSTerHDD) {
	Write-Host "Old image $($AGS30MiSTerHDD) exists, removing."
	$null = Remove-Item -Path $AGS30MiSTerHDD
}
Write-Host "Creating image $($AGS30MiSTerHDD), $($AGS30MiSTerHDDSize) bytes."

# create blank image
& $HSTImagerExe blank $AGS30MiSTerHDD $AGS30MiSTerHDDSize
# initialize rigid disk block
& $HSTImagerExe rdb init $AGS30MiSTerHDD
# import rdb file system pfs3aio with dos type PDS3 from aminet.net
& $HSTImagerExe rdb fs import $AGS30MiSTerHDD https://aminet.net/disk/misc/pfs3aio.lha --dos-type PDS3 --name pfs3aio

# add rdb partition of 1gb with device name "DH0" and set bootable "Workbench"
& $HSTImagerExe rdb part add $AGS30MiSTerHDD DH0 PDS3 600mb --bootable
# add rdb partition of 1.2gb space with device name "DH1" "Work"
& $HSTImagerExe rdb part add $AGS30MiSTerHDD DH1 PDS3 1200mb
# add rdb partition of 3.5gb space with device name "DH2" "Music"
& $HSTImagerExe rdb part add $AGS30MiSTerHDD DH2 PDS3 3500mb
# add rdb partition of 2.8gb space with device name "DH3" "Media"
& $HSTImagerExe rdb part add $AGS30MiSTerHDD DH3 PDS3 2800mb
# add rdb partition of 3.5gb space with device name "DH4" "AGS_Drive"
& $HSTImagerExe rdb part add $AGS30MiSTerHDD DH4 PDS3 3500mb
# add rdb partition of 6.3gb space with device name "DH5" "Games"
& $HSTImagerExe rdb part add $AGS30MiSTerHDD DH5 PDS3 6300mb
# add rdb partition of 7.8gb space with device name "DH6" "Premium"
& $HSTImagerExe rdb part add $AGS30MiSTerHDD DH6 PDS3 7800mb
# add rdb partition of 2.7gb space with device name "DH7" "Emulators1"
& $HSTImagerExe rdb part add $AGS30MiSTerHDD DH7 PDS3 2700mb
# add rdb partition of 5.2gb space with device name "DH8" "Emulators2"
& $HSTImagerExe rdb part add $AGS30MiSTerHDD DH8 PDS3 5200mb
# add rdb partition of 7.5gb space with device name "DH9" "WHD_Games"
& $HSTImagerExe rdb part add $AGS30MiSTerHDD DH9 PDS3 7500mb
# add rdb partition of 1.4gb space with device name "DH10" "WHD_Demos"
& $HSTImagerExe rdb part add $AGS30MiSTerHDD DH10 PDS3 1400mb

# format rdb partition number 1 with volume name "Workbench"
& $HSTImagerExe rdb part format $AGS30MiSTerHDD 1 Workbench
# format rdb partition number 2 with volume name "Work"
& $HSTImagerExe rdb part format $AGS30MiSTerHDD 2 Work
# format rdb partition number 3 with volume name "Music"
& $HSTImagerExe rdb part format $AGS30MiSTerHDD 3 Music
# format rdb partition number 4 with volume name "Media"
& $HSTImagerExe rdb part format $AGS30MiSTerHDD 4 Media
# format rdb partition number 5 with volume name "AGS_Drive"
& $HSTImagerExe rdb part format $AGS30MiSTerHDD 5 AGS_Drive
# format rdb partition number 6 with volume name "Games"
& $HSTImagerExe rdb part format $AGS30MiSTerHDD 6 Games
# format rdb partition number 7 with volume name "Premium"
& $HSTImagerExe rdb part format $AGS30MiSTerHDD 7 Premium
# format rdb partition number 8 with volume name "Emulators1"
& $HSTImagerExe rdb part format $AGS30MiSTerHDD 8 Emulators1
# format rdb partition number 9 with volume name "Emulators2"
& $HSTImagerExe rdb part format $AGS30MiSTerHDD 9 Emulators2
# format rdb partition number 10 with volume name "WHD_Games"
& $HSTImagerExe rdb part format $AGS30MiSTerHDD 10 WHD_Games
# format rdb partition number 11 with volume name "WHD_Demos"
& $HSTImagerExe rdb part format $AGS30MiSTerHDD 11 WHD_Demos


##################################################
# Copy Workbench
$HDFSource = "$($AGS30hdf)\Workbench.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh0" "$($AGS30MiSTerHDD)\rdb\dh0" --recursive --makedir --force
# Copy Work
$HDFSource = "$($AGS30hdf)\Work.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh3" "$($AGS30MiSTerHDD)\rdb\dh1" --recursive --makedir --force
# Copy Music
$HDFSource = "$($AGS30hdf)\Music.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh2" "$($AGS30MiSTerHDD)\rdb\dh2" --recursive --makedir --force
# Copy Media
$HDFSource = "$($AGS30hdf)\Media.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh3" "$($AGS30MiSTerHDD)\rdb\dh3" --recursive --makedir --force
# Copy AGS_Drive
$HDFSource = "$($AGS30hdf)\AGS_Drive.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh4" "$($AGS30MiSTerHDD)\rdb\dh4" --recursive --makedir --force
# Copy Games
$HDFSource = "$($AGS30hdf)\Games.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh5" "$($AGS30MiSTerHDD)\rdb\dh5" --recursive --makedir --force
# Copy Premium
$HDFSource = "$($AGS30hdf)\Premium.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh6" "$($AGS30MiSTerHDD)\rdb\dh6" --recursive --makedir --force
# Copy Emulators1
$HDFSource = "$($AGS30hdf)\Emulators.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh7" "$($AGS30MiSTerHDD)\rdb\dh7" --recursive --makedir --force
# Copy Emulators2
$HDFSource = "$($AGS30hdf)\Emulators2.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh0" "$($AGS30MiSTerHDD)\rdb\dh8" --recursive --makedir --force
# Copy WHD_Games
$HDFSource = "$($AGS30hdf)\WHD_Games.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh9" "$($AGS30MiSTerHDD)\rdb\dh9" --recursive --makedir --force
# Copy WHD_Demos
$HDFSource = "$($AGS30hdf)\WHD_Demos.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh10" "$($AGS30MiSTerHDD)\rdb\dh10" --recursive --makedir --force


##################################################
# show info
& $HSTImagerExe info $AGS30MiSTerHDD


##################################################
# Copy share drivers
& $HSTImagerExe fs extract "$($AmigaFiles)\MiSTer_Tools2.adf\MiSTer_share.lha" $BuildFolder --makedir --force
& $HSTImagerExe fs extract "$($BuildFolder)MiSTer_share.lha\DEVS\dummy.device" "$($AGS30MiSTerHDD)\rdb\dh0\Devs\" --force
& $HSTImagerExe fs extract "$($BuildFolder)MiSTer_share.lha\DEVS\DOSDrivers\SHARE*" "$($AGS30MiSTerHDD)\rdb\dh0\Devs\DOSDrivers\" --makedir --force
& $HSTImagerExe fs extract "$($BuildFolder)MiSTer_share.lha\L\*" "$($AGS30MiSTerHDD)\rdb\dh0\L\" --makedir --force
$null = Remove-Item -Path "$($BuildFolder)MiSTer_share.lha"


##################################################
# Copy RTG drivers
& $HSTImagerExe fs extract "$($AmigaFiles)\MiSTer_Tools2.adf\MiSTer_RTG.lha" $BuildFolder --makedir --force
& $HSTImagerExe fs extract "$($BuildFolder)MiSTer_RTG.lha" "$($AGS30MiSTerHDD)\rdb\dh0\" --recursive --makedir --force
$null = Remove-Item -Path "$($BuildFolder)MiSTer_RTG.lha"


##################################################
# Copy AHI Toccata drivers
& $HSTImagerExe fs extract "$($AHIPath)\AHI\User\Devs\AHI\toccata.*" "$($AGS30MiSTerHDD)\rdb\dh0\Devs\ahi\" --makedir --force
& $HSTImagerExe fs extract "$($AHIPath)\AHI\User\Devs\AudioModes\TOCCATA" "$($AGS30MiSTerHDD)\rdb\dh0\Devs\audiomodes\" --makedir --force


##################################################
# Copy Workbench Patches
$AmigaFilesAGS = "$($AmigaFiles)\AGS30\Workbench"
#& $HSTImagerExe fs copy "$($AmigaFilesAGS)\Devs\*" "$($AGS30MiSTerHDD)\rdb\dh0\Devs\" --recursive --makedir --force
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\Devs\scsi.*" "$($AGS30MiSTerHDD)\rdb\dh0\Devs\" --recursive --makedir --force
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\Devs\Picasso96Settings" "$($AGS30MiSTerHDD)\rdb\dh0\Devs\" --recursive --makedir --force

#& $HSTImagerExe fs copy "$($AmigaFilesAGS)\S\*" "$($AGS30MiSTerHDD)\rdb\dh0\S\" --recursive --makedir --force
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\S\startup-sequence" "$($AGS30MiSTerHDD)\rdb\dh0\S\" --force
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\S\user-startup" "$($AGS30MiSTerHDD)\rdb\dh0\S\" --force
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\S\AGS-Stuff" "$($AGS30MiSTerHDD)\rdb\dh0\S\" --force
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\S\ToolsDaemonMenus\*" "$($AGS30MiSTerHDD)\rdb\dh0\S\ToolsDaemonMenus\" --force

#& $HSTImagerExe fs copy "$($AmigaFilesAGS)\Prefs\*" "$($AGS30MiSTerHDD)\rdb\dh0\Prefs\" --recursive --makedir --force
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\Prefs\Env-Archive\HW" "$($AGS30MiSTerHDD)\rdb\dh0\Prefs\Env-Archive\" --force
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\Prefs\Env-Archive\MiSTer" "$($AGS30MiSTerHDD)\rdb\dh0\Prefs\Env-Archive\" --force
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\Prefs\Env-Archive\whdlsaves" "$($AGS30MiSTerHDD)\rdb\dh0\Prefs\Env-Archive\" --force
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\Prefs\Env-Archive\Sys\ahi.prefs" "$($AGS30MiSTerHDD)\rdb\dh0\Prefs\Env-Archive\Sys\" --force
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\Prefs\Env-Archive\Sys\screenmode.prefs" "$($AGS30MiSTerHDD)\rdb\dh0\Prefs\Env-Archive\Sys\" --force

& $HSTImagerExe fs copy "$($AmigaFilesAGS)\WBStartup\*" "$($AGS30MiSTerHDD)\rdb\dh0\WBStartup\" --force


##################################################
# Copy Work Patches
$AmigaFilesAGS = "$($AmigaFiles)\AGS30\Work"
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\Web\Miami\*" "$($AGS30MiSTerHDD)\rdb\dh1\Web\Miami\" --force


##################################################
# Copy AGS_Drive Patches
$AmigaFilesAGS = "$($AmigaFiles)\AGS30\AGS_Drive"
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\AGS2\Scripts\*" "$($AGS30MiSTerHDD)\rdb\dh4\AGS2\Scripts\" --force


##################################################
# Patch RTG screen mode on AGS themes
# https://m68k.aminet.net/package/util/boot/ModeIDList123
# Original Modes in themes
# mode = $500A1000 -> UAE: 640x512 8bit
# mode = $508E1000 -> UAE: 1280x720 8bit
# mode = $29004 -> PAL: High Res Laced
# MiSTer RTG Mode for AGS
# mode = $50061000 -> MiSTer: 640x512 8bit
$SMThemePatch = "$($BuildFolder)SMThemePatch\"
& $HSTImagerExe fs copy "$($AGS30hdf)\AGS_Drive.hdf\rdb\dh4\AGS2\Themes\*.conf" $SMThemePatch --makedir --force
$null = ReplaceInFiles -Path $SMThemePatch -Filter '*.conf' -Pattern 'mode = $500A1000' -Replacement 'mode = $50061000' -Encoding 'ascii' -CaseSensitive #-Backup
$null = ReplaceInFiles -Path $SMThemePatch -Filter '*.conf' -Pattern 'mode = $508E1000' -Replacement 'mode = $50061000' -Encoding 'ascii' -CaseSensitive #-Backup
$null = ReplaceInFiles -Path $SMThemePatch -Filter '*.conf' -Pattern 'mode = $29004' -Replacement 'mode = $50061000' -Encoding 'ascii' -CaseSensitive #-Backup
& $HSTImagerExe fs copy "$($SMThemePatch)*.conf" "$($AGS30MiSTerHDD)\rdb\dh4\AGS2\Themes\" --force
# Default theme patched
& $HSTImagerExe fs copy "$($SMThemePatch)default.conf" "$($AGS30MiSTerHDD)\rdb\dh4\AGS2\ags2.conf" --force
$null = Remove-Item -Path $SMThemePatch -Recurse


##################################################
# Extract Kickstart
$HDFSource = "$($AGS30hdf)\Workbench.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh0\Devs\Kickstarts\kick40068.A1200" "$($BuildRoot)KICK.ROM" --force


Write-Host "Done"
