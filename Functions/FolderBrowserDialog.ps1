# add WinForm assembly for dialogs
Add-Type -AssemblyName System.Windows.Forms

# show folder browser dialog using WinForm
Function FolderBrowserDialog($title, $directory, $showNewFolderButton)
{
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowserDialog.Description = $title
    $folderBrowserDialog.SelectedPath = $directory
    $folderBrowserDialog.ShowNewFolderButton = $showNewFolderButton
    $result = $folderBrowserDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))

    if($result -ne "OK")
    {
        return $null
    }

    return $folderBrowserDialog.SelectedPath
}