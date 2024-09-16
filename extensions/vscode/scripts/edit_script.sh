#!/bin/bash

# this script is executed from ps1 script, which passes the wslUser
wslUser=$1
commitId=$2

commitId="5849ca9bdf9666755eb463db297b69e5385090e3"

filePath="/home/$wslUser/.pearai-server/bin/$commitId/out/vs/server/node/server.main.js"

# Check if the file exists
if [ ! -f "$filePath" ]; then
    echo "File not found: $filePath"
    exit 1
fi

# sed -i "s/if(!\\([A-Za-z0-9_]*\\)){if(this\.\([A-Za-z0-9_]*\).isBuilt)return Z("Unauthorized client refused");/if(\\1)/g" "$1"

# replacement operation
sed -i '0,/if(!\([A-Za-z0-9_]*\)){if(this\.\([A-Za-z0-9_]*\)\.isBuilt)return \([A-Za-z0-9_]*\)(\"Unauthorized client refused\");/s//if(\1){if(this.\2.isBuilt)return \3("Unauthorized client refused");/' "$filePath"

# Check if the sed command was successful
if [ $? -eq 0 ]; then
    echo "File successfully modified: $filePath"
    echo "Commit ID: $commitId"
else
    echo "Failed to modify the file: $filePath"
    exit 1
fi
