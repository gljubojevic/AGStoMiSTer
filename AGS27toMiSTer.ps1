# variables and definitions
$FunctionsFolder = '.\Functions\'
$ToolsFolder = '.\Tools\'
$BuildFolder = '.\Build\'

# HST-Imager
$HSTImagerDownload = "https://github.com/henrikstengaard/hst-imager/releases/download/1.4.526/hst-imager_v1.4.526-e74dd1a_console_windows_x64.zip"
$HSTImagerPath = "$($ToolsFolder)hst-imager.zip"
$HSTImager = "$($ToolsFolder)hst-imager\"
$HSTImagerExe = "$($ToolsFolder)hst-imager\hst.imager.exe"

# Image Path
$AGS27MiSTerImage = "$($BuildFolder)AGS27MiSTer.hdf"
# Image Size 55GB + 3.5MB (Partition table)
$AGS27MiSTerImageSize = (1024 * 1024 * 1024 * 55) + (1024 * 1024 * 3.5)
# Image Size 2GB test
# $AGS27MiSTerImageSize = (1024 * 1024 * 1024 * 2)

# Load all functions
Get-ChildItem -Path $FunctionsFolder -Recurse | Where-Object { $_.PSIsContainer -eq $false } | ForEach-Object {
    . ($_).fullname
}

# Main code
Write-Host "Starting ..."

# HST-Imager download and extract
if ((Confirm-FileExists -PathToCheck $HSTImagerPath) -eq $false){
	$ok = Get-DownloadFile -DownloadURL $HSTImagerDownload -OutputLocation  $HSTImagerPath -NumberOfAttempts 2
	if ($ok -eq $false) {
		throw "Download of $($HSTImagerDownload) failed"
	}
}
if ((Test-Path $HSTImager) -eq $false) {
	Expand-Archive -LiteralPath $HSTImagerPath -DestinationPath $HSTImager
}

# Hardcode images position
# $AGS27hdf = "E:\Download\AGS_UAE_v27\AGS_UAE_v27\WinUAE\AGS_UAE"
# Select folder with AGS UAE HD files
if (-not $AGS27hdf) {
	$AGS27hdf = FolderBrowserDialog "Select folder with AGS UAE 2.7 HDF files" $currentPath
}
if ($null -eq $AGS27hdf) {
	throw "AGS UAE 2.7 folder with HDF files not selected"
}
# check for all HDF files
# Workbench.hdf
$HDFCheck = "$($AGS27hdf)\Workbench.hdf"
if (-not (Test-path $HDFCheck)){
	throw "Required HDF file $($HDFCheck) does not exist."
} 
# AGS_Drive.hdf
$HDFCheck = "$($AGS27hdf)\AGS_Drive.hdf"
if (-not (Test-path $HDFCheck)){
	throw "Required HDF file $($HDFCheck) does not exist."
} 
# Games.hdf
$HDFCheck = "$($AGS27hdf)\Games.hdf"
if (-not (Test-path $HDFCheck)){
	throw "Required HDF file $($HDFCheck) does not exist."
} 
# Extra.hdf
$HDFCheck = "$($AGS27hdf)\Extra.hdf"
if (-not (Test-path $HDFCheck)){
	throw "Required HDF file $($HDFCheck) does not exist."
} 
# Work.hdf
$HDFCheck = "$($AGS27hdf)\Work.hdf"
if (-not (Test-path $HDFCheck)){
	throw "Required HDF file $($HDFCheck) does not exist."
} 
# Media.hdf
$HDFCheck = "$($AGS27hdf)\Media.hdf"
if (-not (Test-path $HDFCheck)){
	throw "Required HDF file $($HDFCheck) does not exist."
} 

# Create image
if (Test-Path $AGS27MiSTerImage) {
	Write-Host "Old image $($AGS27MiSTerImage) exists, removing."
	$null = Remove-Item -Path $AGS27MiSTerImage
}
Write-Host "Creating image $($AGS27MiSTerImage), $($AGS27MiSTerImageSize) bytes."

# create blank image
& $HSTImagerExe blank $AGS27MiSTerImage $AGS27MiSTerImageSize --verbose
# initialize rigid disk block
& $HSTImagerExe rdb init $AGS27MiSTerImage
# import rdb file system pfs3aio with dos type PDS3 from aminet.net
& $HSTImagerExe rdb fs import $AGS27MiSTerImage https://aminet.net/disk/misc/pfs3aio.lha --dos-type PDS3 --name pfs3aio

# add rdb partition of 1gb with device name "DH0" and set bootable "Workbench"
& $HSTImagerExe rdb part add $AGS27MiSTerImage DH0 PDS3 1gb --bootable --verbose
# add rdb partition of 16gb space with device name "DH1" "AGS_Drive"
& $HSTImagerExe rdb part add $AGS27MiSTerImage DH1 PDS3 16gb --verbose
# add rdb partition of 8gb space with device name "DH2" "Games"
& $HSTImagerExe rdb part add $AGS27MiSTerImage DH2 PDS3 8gb --verbose
# add rdb partition of 16gb space with device name "DH3" "Extra"
& $HSTImagerExe rdb part add $AGS27MiSTerImage DH3 PDS3 16gb --verbose
# add rdb partition of 4gb space with device name "DH4" "Work"
& $HSTImagerExe rdb part add $AGS27MiSTerImage DH4 PDS3 4gb --verbose
# add rdb partition of 10gb space with device name "DH5" "Media"
& $HSTImagerExe rdb part add $AGS27MiSTerImage DH5 PDS3 10gb --verbose

# format rdb partition number 1 with volume name "Workbench"
& $HSTImagerExe rdb part format $AGS27MiSTerImage 1 Workbench --verbose
# format rdb partition number 2 with volume name "AGS_Drive"
& $HSTImagerExe rdb part format $AGS27MiSTerImage 2 AGS_Drive --verbose
# format rdb partition number 3 with volume name "Games"
& $HSTImagerExe rdb part format $AGS27MiSTerImage 3 Games --verbose
# format rdb partition number 4 with volume name "Extra"
& $HSTImagerExe rdb part format $AGS27MiSTerImage 4 Extra --verbose
# format rdb partition number 5 with volume name "Work"
& $HSTImagerExe rdb part format $AGS27MiSTerImage 5 Work --verbose
# format rdb partition number 6 with volume name "Media"
& $HSTImagerExe rdb part format $AGS27MiSTerImage 6 Media --verbose

# show info
& $HSTImagerExe info $AGS27MiSTerImage

# Copy Workbench
$HDFSource = "$($AGS27hdf)\Workbench.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh0" "$($AGS27MiSTerImage)\rdb\dh0" --recursive --makedir --force --verbose
# Copy AGS_Drive
$HDFSource = "$($AGS27hdf)\AGS_Drive.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh1" "$($AGS27MiSTerImage)\rdb\dh1" --recursive --makedir --force --verbose
# Copy Games
$HDFSource = "$($AGS27hdf)\Games.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh2" "$($AGS27MiSTerImage)\rdb\dh2" --recursive --makedir --force --verbose
# Copy Extra
$HDFSource = "$($AGS27hdf)\Extra.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh3" "$($AGS27MiSTerImage)\rdb\dh3" --recursive --makedir --force --verbose
# Copy Work
$HDFSource = "$($AGS27hdf)\Work.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh4" "$($AGS27MiSTerImage)\rdb\dh5" --recursive --makedir --force --verbose
# Copy Media
$HDFSource = "$($AGS27hdf)\Media.hdf"
& $HSTImagerExe fs copy "$($HDFSource)\rdb\dh6" "$($AGS27MiSTerImage)\rdb\dh6" --recursive --makedir --force --verbose

Write-Host "Done"
