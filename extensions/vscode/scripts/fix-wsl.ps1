param (
    [Parameter(Mandatory=$true)]
    [string]$CommitId
)


# Get the WSL username
$wslUser = wsl -e bash -c "whoami"

# Define the local path of the script
$patchScriptLocal = Join-Path $PSScriptRoot "edit_script.sh"
# Write-Output $patchScriptLocal

# Convert Windows path to WSL path
$wslPath = $patchScriptLocal -replace '^([A-Za-z]):', '/mnt/$1' -replace '\\', '/'
$wslPath = $wslPath.ToLower()

# Define the temporary script path in WSL
$tempScriptPath = "/tmp/edit_script.sh"

# Copy the script file from Windows to WSL
wsl -e bash -c "cp '$wslPath' $tempScriptPath && chmod +x $tempScriptPath"

# Verify the script file exists
$fileCheckCommand = "if [ -f $tempScriptPath ]; then echo 'File exists'; else echo 'File does not exist'; fi"
$fileCheckResult = wsl -e bash -c "$fileCheckCommand"
Write-Output "File check result: $fileCheckResult"

if ($fileCheckResult -eq "File exists") {
    # Execute the script in WSL with the WSL username as an argument
    $result = wsl -e bash -c "$tempScriptPath '$wslUser' '$CommitId' '$Version'"

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
