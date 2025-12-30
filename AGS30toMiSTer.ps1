# variables and definitions
$AmigaFiles = ".\AmigaFiles"
$FunctionsFolder = '.\Functions\'
$ToolsFolder = '.\Tools\'
$BuildFolder = '.\Build\'
#$BuildFolder = 'C:\Log\'
$BuildHDD = "$($BuildFolder)games\AmigaGameSelector30\HDD\"

# HST-Imager
$HSTImagerDownload = "https://github.com/henrikstengaard/hst-imager/releases/download/1.4.526/hst-imager_v1.4.526-e74dd1a_console_windows_x64.zip"
$HSTImagerPath = "$($ToolsFolder)hst-imager.zip"
$HSTImager = "$($ToolsFolder)hst-imager\"
$HSTImagerExe = "$($ToolsFolder)hst-imager\hst.imager.exe"

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
# Create primary image
$AGS30MiSTerPrimary = "$($BuildHDD)AGS30MiSTer_Primary.hdf"
# Primary image Size 600 + 1.464MB (Partition table)
$AGS30MiSTerPrimarySize = (MBtoBytes 600) + (MBtoBytes 1) + (KBtoBytes 464)

if (Test-Path $AGS30MiSTerPrimary) {
	Write-Host "Old image $($AGS30MiSTerPrimary) exists, removing."
	$null = Remove-Item -Path $AGS30MiSTerPrimary
}
Write-Host "Creating image $($AGS30MiSTerPrimary), $($AGS30MiSTerPrimarySize) bytes."

# create blank image
& $HSTImagerExe blank $AGS30MiSTerPrimary $AGS30MiSTerPrimarySize #--verbose
# initialize rigid disk block
& $HSTImagerExe rdb init $AGS30MiSTerPrimary
# import rdb file system pfs3aio with dos type PDS3 from aminet.net
& $HSTImagerExe rdb fs import $AGS30MiSTerPrimary https://aminet.net/disk/misc/pfs3aio.lha --dos-type PDS3 --name pfs3aio #--verbose

# add rdb partition of 1gb with device name "DH0" and set bootable "Workbench"
& $HSTImagerExe rdb part add $AGS30MiSTerPrimary DH0 PDS3 600mb --bootable #--verbose

# format rdb partition number 1 with volume name "Workbench"
& $HSTImagerExe rdb part format $AGS30MiSTerPrimary 1 Workbench #--verbose

##################################################
# Copy Workbench
$HDFSource = "$($AGS30hdf)\Workbench.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh0" "$($AGS30MiSTerPrimary)\rdb\dh0" --recursive --makedir --force #--verbose


##################################################
# Patch primary image
$AGS30MiSTerImage = $AGS30MiSTerPrimary

<#
##################################################
# Copy share drivers
& $HSTImagerExe fs extract "$($AmigaFiles)\MiSTer_Tools2.adf\MiSTer_share.lha" $BuildFolder --makedir --force
& $HSTImagerExe fs extract "$($BuildFolder)MiSTer_share.lha\DEVS\dummy.device" "$($AGS30MiSTerImage)\rdb\dh0\Devs\" --force --verbose
& $HSTImagerExe fs extract "$($BuildFolder)MiSTer_share.lha\DEVS\DOSDrivers\SHARE*" "$($AGS30MiSTerImage)\rdb\dh0\Devs\DOSDrivers\" --makedir --force --verbose
& $HSTImagerExe fs extract "$($BuildFolder)MiSTer_share.lha\L\*" "$($AGS30MiSTerImage)\rdb\dh0\L\" --makedir --force --verbose
$null = Remove-Item -Path "$($BuildFolder)MiSTer_share.lha"
#>

<#
##################################################
# Copy RTG drivers
& $HSTImagerExe fs extract "$($AmigaFiles)\MiSTer_Tools2.adf\MiSTer_RTG.lha" $BuildFolder --makedir --force
& $HSTImagerExe fs extract "$($BuildFolder)MiSTer_RTG.lha" "$($AGS30MiSTerImage)\rdb\dh0\" --recursive --makedir --force --verbose
$null = Remove-Item -Path "$($BuildFolder)MiSTer_RTG.lha"
#>

<#
##################################################
# Copy AGS Patches
$AmigaFilesAGS = "$($AmigaFiles)\AGS30"
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\s\*" "$($AGS30MiSTerImage)\rdb\dh0\s\" --force --verbose
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\Prefs\Sys\*" "$($AGS30MiSTerImage)\rdb\dh0\Prefs\Sys\" --force --verbose
& $HSTImagerExe fs copy "$($AmigaFilesAGS)\Prefs\Env-Archive\*" "$($AGS30MiSTerImage)\rdb\dh0\Prefs\Env-Archive\" --force --verbose
#>


##################################################
# Create secondary image
$AGS30MiSTerSecondary = "$($BuildHDD)AGS30MiSTer_Secondary.hdf"
# Secondary image Size 1.2GB + 3.5GB + 2.8GB + 3.5GB + 6.3GB + 7.8GB + 2.7GB + 5.2gb + 7.5gb + 1.4gb + 3.952MB (Partition table)
$AGS30MiSTerSecondarySize = (MBtoBytes 1200) + (MBtoBytes 3500) + (MBtoBytes 2800) + (MBtoBytes 3500) + (MBtoBytes 6300) + (MBtoBytes 7800) + (MBtoBytes 2700) + (MBtoBytes 5200) + (MBtoBytes 7500) + (MBtoBytes 1400) + (KBtoBytes 3952)

if (Test-Path $AGS30MiSTerSecondary) {
	Write-Host "Old image $($AGS30MiSTerSecondary) exists, removing."
	$null = Remove-Item -Path $AGS30MiSTerSecondary
}
Write-Host "Creating image $($AGS30MiSTerSecondary), $($AGS30MiSTerSecondarySize) bytes."

# create blank image
& $HSTImagerExe blank $AGS30MiSTerSecondary $AGS30MiSTerSecondarySize #--verbose
# initialize rigid disk block
& $HSTImagerExe rdb init $AGS30MiSTerSecondary
# import rdb file system pfs3aio with dos type PDS3 from aminet.net
& $HSTImagerExe rdb fs import $AGS30MiSTerSecondary https://aminet.net/disk/misc/pfs3aio.lha --dos-type PDS3 --name pfs3aio #--verbose

# add rdb partition of 1.2gb space with device name "DH1" "Work"
& $HSTImagerExe rdb part add $AGS30MiSTerSecondary DH1 PDS3 1200mb #--verbose
# add rdb partition of 3.5gb space with device name "DH2" "Music"
& $HSTImagerExe rdb part add $AGS30MiSTerSecondary DH2 PDS3 3500mb #--verbose
# add rdb partition of 2.8gb space with device name "DH3" "Media"
& $HSTImagerExe rdb part add $AGS30MiSTerSecondary DH3 PDS3 2800mb #--verbose
# add rdb partition of 3.5gb space with device name "DH4" "AGS_Drive"
& $HSTImagerExe rdb part add $AGS30MiSTerSecondary DH4 PDS3 3500mb #--verbose
# add rdb partition of 6.3gb space with device name "DH5" "Games"
& $HSTImagerExe rdb part add $AGS30MiSTerSecondary DH5 PDS3 6300mb #--verbose
# add rdb partition of 7.8gb space with device name "DH6" "Premium"
& $HSTImagerExe rdb part add $AGS30MiSTerSecondary DH6 PDS3 7800mb #--verbose
# add rdb partition of 2.7gb space with device name "DH7" "Emulators1"
& $HSTImagerExe rdb part add $AGS30MiSTerSecondary DH7 PDS3 2700mb #--verbose
# add rdb partition of 5.2gb space with device name "DH8" "Emulators2"
& $HSTImagerExe rdb part add $AGS30MiSTerSecondary DH8 PDS3 5200mb #--verbose
# add rdb partition of 7.5gb space with device name "DH9" "WHD_Games"
& $HSTImagerExe rdb part add $AGS30MiSTerSecondary DH9 PDS3 7500mb #--verbose
# add rdb partition of 1.4gb space with device name "DH10" "WHD_Demos"
& $HSTImagerExe rdb part add $AGS30MiSTerSecondary DH10 PDS3 1400mb #--verbose

# format rdb partition number 1 with volume name "Work"
& $HSTImagerExe rdb part format $AGS30MiSTerSecondary 1 Work #--verbose
# format rdb partition number 2 with volume name "Music"
& $HSTImagerExe rdb part format $AGS30MiSTerSecondary 2 Music #--verbose
# format rdb partition number 3 with volume name "Media"
& $HSTImagerExe rdb part format $AGS30MiSTerSecondary 3 Media #--verbose
# format rdb partition number 4 with volume name "AGS_Drive"
& $HSTImagerExe rdb part format $AGS30MiSTerSecondary 4 AGS_Drive #--verbose
# format rdb partition number 5 with volume name "Games"
& $HSTImagerExe rdb part format $AGS30MiSTerSecondary 5 Games #--verbose
# format rdb partition number 6 with volume name "Premium"
& $HSTImagerExe rdb part format $AGS30MiSTerSecondary 6 Premium #--verbose
# format rdb partition number 7 with volume name "Emulators1"
& $HSTImagerExe rdb part format $AGS30MiSTerSecondary 7 Emulators1 #--verbose
# format rdb partition number 8 with volume name "Emulators2"
& $HSTImagerExe rdb part format $AGS30MiSTerSecondary 8 Emulators2 #--verbose
# format rdb partition number 9 with volume name "WHD_Games"
& $HSTImagerExe rdb part format $AGS30MiSTerSecondary 9 WHD_Games #--verbose
# format rdb partition number 10 with volume name "WHD_Demos"
& $HSTImagerExe rdb part format $AGS30MiSTerSecondary 10 WHD_Demos #--verbose

##################################################
# Copy Work
$HDFSource = "$($AGS30hdf)\Work.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh3" "$($AGS30MiSTerSecondary)\rdb\dh1" --recursive --makedir --force #--verbose
# Copy Music
$HDFSource = "$($AGS30hdf)\Music.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh2" "$($AGS30MiSTerSecondary)\rdb\dh2" --recursive --makedir --force #--verbose
# Copy Media
$HDFSource = "$($AGS30hdf)\Media.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh3" "$($AGS30MiSTerSecondary)\rdb\dh3" --recursive --makedir --force #--verbose
# Copy AGS_Drive
$HDFSource = "$($AGS30hdf)\AGS_Drive.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh4" "$($AGS30MiSTerSecondary)\rdb\dh4" --recursive --makedir --force #--verbose
# Copy Games
$HDFSource = "$($AGS30hdf)\Games.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh5" "$($AGS30MiSTerSecondary)\rdb\dh5" --recursive --makedir --force #--verbose
# Copy Premium
$HDFSource = "$($AGS30hdf)\Premium.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh6" "$($AGS30MiSTerSecondary)\rdb\dh6" --recursive --makedir --force #--verbose
# Copy Emulators1
$HDFSource = "$($AGS30hdf)\Emulators.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh7" "$($AGS30MiSTerSecondary)\rdb\dh7" --recursive --makedir --force #--verbose
# Copy Emulators2
$HDFSource = "$($AGS30hdf)\Emulators2.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh0" "$($AGS30MiSTerSecondary)\rdb\dh8" --recursive --makedir --force #--verbose
# Copy WHD_Games
$HDFSource = "$($AGS30hdf)\WHD_Games.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh9" "$($AGS30MiSTerSecondary)\rdb\dh9" --recursive --makedir --force #--verbose
# Copy WHD_Demos
$HDFSource = "$($AGS30hdf)\WHD_Demos.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh10" "$($AGS30MiSTerSecondary)\rdb\dh10" --recursive --makedir --force #--verbose

##################################################
# Patch secondary image
# $AGS30MiSTerImage = $AGS30MiSTerSecondary


##################################################
# show info
& $HSTImagerExe info $AGS30MiSTerPrimary
& $HSTImagerExe info $AGS30MiSTerSecondary

Write-Host "Done"
