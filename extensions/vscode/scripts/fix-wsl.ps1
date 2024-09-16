param (
    [Parameter(Mandatory=$true)]
    [string]$wslDownloadScript,

    [Parameter(Mandatory=$true)]
    [string]$CommitId
)


# Get the WSL username
$wslUser = wsl -e bash -c "whoami"

$patchScriptLocal = Join-Path $PSScriptRoot "edit_script.sh"
# Write-Output $patchScriptLocal

# Convert Windows path to Unix path
$patchScriptLocal_InWSL = $patchScriptLocal -replace '^([A-Za-z]):', '/mnt/$1' -replace '\\', '/'
$patchScriptLocal_InWSL = $patchScriptLocal_InWSL.ToLower()

$wslDownloadScript_InWSL = $wslDownloadScript -replace '^([A-Za-z]):', '/mnt/$1' -replace '\\', '/'
$wslDownloadScript_InWSL = $wslDownloadScript_InWSL.ToLower()

# temporary script path in WSL
$tempScriptPath = "/tmp/edit_script.sh"

# Copy the script file from Windows to WSL
wsl -e bash -c "cp '$patchScriptLocal_InWSL' $tempScriptPath && chmod +x $tempScriptPath"

# Verify the script file exists
$fileCheckCommand = "if [ -f $tempScriptPath ]; then echo 'File exists'; else echo 'File does not exist'; fi"
$fileCheckResult = wsl -e bash -c "$fileCheckCommand"
Write-Output "File check result: $fileCheckResult"

if ($fileCheckResult -eq "File exists") {
    # Execute the script in WSL with the WSL username as an argument
Write-Output "Executing WSL download script: $wslDownloadScript_InWSL"

try {
    $timeoutSeconds = 300  # Set a timeout of 5 minutes (adjust as needed)
    $job = Start-Job -ScriptBlock {
        param($wslDownloadScript_InWSL, $CommitId)
        wsl -e bash -c "bash '$wslDownloadScript_InWSL' '$CommitId' 'stable' '/home$wsluser/.pearai-server/bin'"
    } -ArgumentList $wslDownloadScript_InWSL, $CommitId

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
}
    # $result = wsl -e bash -c "$tempScriptPath '$wslUser' '$wslDownloadScript_InWSL' '$CommitId' '$Version'"
    # Write-Output $result

    # Check if the command was successful
    if ($LASTEXITCODE -eq 0) {
        Write-Output "The file has been processed. If the pattern was found, it has been replaced."
    } else {
        Write-Output "An error occurred while trying to edit the file."
    }

    # Clean up the temporary script
    wsl -e bash -c "rm $tempScriptPath"
} else {
    Write-Output "The temporary script file was not created successfully."
}
