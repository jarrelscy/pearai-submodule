param (
    [Parameter(Mandatory=$true)]
    [string]$wslDownloadScript,

    [Parameter(Mandatory=$true)]
    [string]$PEAR_COMMIT_ID,

    [Parameter(Mandatory=$true)]
    [string]$VSC_COMMIT_ID    
)

# ----------------------------

# Get the WSL username
$wslUser = wsl -e bash -c "whoami"

# ----------------------------

# Convert Windows paths to WSL paths
$patchScriptLocal = Join-Path $PSScriptRoot "edit_script.sh"
$patchScriptLocal_InWSL = $patchScriptLocal -replace '^([A-Za-z]):', '/mnt/$1' -replace '\\', '/'
$patchScriptLocal_InWSL = $patchScriptLocal_InWSL.ToLower()

$wslDownloadScript_InWSL = $wslDownloadScript -replace '^([A-Za-z]):', '/mnt/$1' -replace '\\', '/'
$wslDownloadScript_InWSL = $wslDownloadScript_InWSL.ToLower()

# Define temporary script paths in WSL
$tempEditScriptPath = "/tmp/edit_script.sh"
$tempDownloadScriptPath = "/tmp/download_script.sh"

# ----------------------------

# Copy both scripts to WSL
wsl -e bash -c "cp '$patchScriptLocal_InWSL' $tempEditScriptPath && chmod +x $tempEditScriptPath"
wsl -e bash -c "cp '$wslDownloadScript_InWSL' $tempDownloadScriptPath && chmod +x $tempDownloadScriptPath"

# ----------------------------

# Verify the script files exist
# $fileCheckCommand = "if [ -f $tempEditScriptPath ] && [ -f $tempDownloadScriptPath ]; then echo 'Files exist'; else echo 'Files do not exist'; fi"
# # $fileCheckResult = wsl -e bash -c "$fileCheckCommand"

$downloadfileCheckResult = wsl -e bash -c "if [ -f $tempDownloadScriptPath ]; then echo 'download file exist'; else echo 'download file do not exist'; fi"
if ($downloadfileCheckResult -ne "download file exist") {
    Write-Output "temporary download script was not created successfully: $downloadfileCheckResult"
    exit 1
}

$editfileCheckResult = wsl -e bash -c "if [ -f $tempEditScriptPath ]; then echo 'edit file exist'; else echo 'edit file do not exist'; fi"
if ($editfileCheckResult -ne "edit file exist") {
    Write-Output "temporary edit script was not created successfully: $editfileCheckResult"
    exit 1
}

# ----------------------------

Write-Output "Executing WSL download script"

try {
    $timeoutSeconds = 300  # Set a timeout of 5 minutes (adjust as needed)
    $job = Start-Job -ScriptBlock {
        param($tempDownloadScriptPath, $PEAR_COMMIT_ID, $wslUser)
        wsl -e bash -c "$tempDownloadScriptPath '4849ca9bdf9666755eb463db297b69e5385090e3' 'stable' '/home/$wslUser/.pearai-server/bin'"
    } -ArgumentList $tempDownloadScriptPath, $PEAR_COMMIT_ID, $wslUser

    $result = $job | Wait-Job -Timeout $timeoutSeconds | Receive-Job
    Write-Output $result

    if ($job.State -eq 'Running') {
        Stop-Job $job
        Remove-Job $job -Force
        Write-Warning "The WSL download script timed out after $timeoutSeconds seconds."
    }
    else {
        Write-Output "Download script output:"
        Write-Output $result
    }
}
catch {
    Write-Error "An error occurred while executing the WSL download script: $_"
}

if ($LASTEXITCODE -ne 0) {
    Write-Warning "The WSL download script exited with a non-zero status code: $LASTEXITCODE"
}
else {
    Write-Output "WSL download script executed successfully."
    
    # Now execute the edit script
    $editResult = wsl -e bash -c "bash '$tempEditScriptPath' '$wslUser' '$PEAR_COMMIT_ID' '$VSC_COMMIT_ID'"
    Write-Output $editResult

    if ($LASTEXITCODE -eq 0) {
        Write-Output "The file has been processed successfully."
    } else {
        Write-Output "An error occurred while trying to edit the file."
    }
}

# ----------------------------

# Clean up the temporary scripts
wsl -e bash -c "rm $tempEditScriptPath $tempDownloadScriptPath"
