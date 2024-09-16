#!/bin/bash

# Set -x for debug output
set -x


# this script is executed from ps1 script, which passes the wslUser
wslUser=$1
wslDownloadScript=$2
commitId=$3
# test commit id - 
commitId="4849ca9bdf9666755eb463db297b69e5385090e3"

pearServerLocation="~/.pearai-server/bin"
quality="stable" # pear only has stable right now, no insiders.


echo $wslDownloadScript

# Check if the wslDownloadScript exists
if [ ! -f "$wslDownloadScript" ]; then
    echo "WSL Download Script not found: $wslDownloadScript"
    exit 1
fi

# Execute the wslDownloadScript and wait for it to complete
if [ -x "$wslDownloadScript" ]; then
    echo "Executing wslDownloadScript: $wslDownloadScript '$commitId' '$quality' '$pearServerLocation'"
    # Use eval to properly handle spaces and quotes in arguments
    eval "$wslDownloadScript '$commitId' '$quality' '$pearServerLocation'" &
    wait $!
    exitCode=$?
    if [ $exitCode -eq 0 ]; then
        echo "wslDownloadScript executed successfully"
    else
        echo "Error: wslDownloadScript failed with exit code $exitCode"
        exit 1
    fi
else
    echo "Error: wslDownloadScript is not executable or doesn't exist: $wslDownloadScript"
    exit 1
fi


# serverFile="/home/$wslUser/.pearai-server/bin/$commitId/out/vs/server/node/server.main.js"
# # Check if the serverFile exists
# if [ ! -f "$serverFile" ]; then
#     echo "Server file not found: $serverFile"
#     exit 1
# fi

# # sed -i "s/if(!\\([A-Za-z0-9_]*\\)){if(this\.\([A-Za-z0-9_]*\).isBuilt)return Z("Unauthorized client refused");/if(\\1)/g" "$1"

# # replacement operation
# sed -i '0,/if(!\([A-Za-z0-9_]*\)){if(this\.\([A-Za-z0-9_]*\)\.isBuilt)return \([A-Za-z0-9_]*\)(\"Unauthorized client refused\");/s//if(\1){if(this.\2.isBuilt)return \3("Unauthorized client refused");/' "$serverFile"

# # Check if the sed command was successful
# if [ $? -eq 0 ]; then
#     echo "File successfully modified: $serverFile"
#     echo "Commit ID: $commitId"
# else
#     echo "Failed to modify the file: $serverFile"
#     exit 1
# fi
