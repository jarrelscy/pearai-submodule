#!/bin/bash

# * Save this script with EOL as LF, otherwise it will fail to run
# * this script will be executed from ps1 script
# * this script is intended to be run inside the WSL environment

# Set -x for debug output
# set -x

wslUser=$1
PEAR_COMMIT_ID=$2
VSC_COMMIT_ID=$3
quality="stable" # pear only has stable right now, no insiders.

# ----------------------------

pearServerLocation="/home/$wslUser/.pearai-server/bin"
serverFile="$pearServerLocation/$VSC_COMMIT_ID/out/vs/server/node/server.main.js"
productJsonFile="$pearServerLocation/$VSC_COMMIT_ID/product.json"

# ----------------------------

# Check if the serverFile exists
if [ ! -f "$serverFile" ]; then
    echo "Server file not found: $serverFile"
    exit 1
fi

# patch the server file
sed -i '0,/if(!\([A-Za-z0-9_]*\)){if(this\.\([A-Za-z0-9_]*\)\.isBuilt)return \([A-Za-z0-9_]*\)(\"Unauthorized client refused\");/s//if(\1){if(this.\2.isBuilt)return \3("Unauthorized client refused");/' "$serverFile"

# Check if the sed command was successful
if [ $? -eq 0 ]; then
    echo "File successfully patched server file: $serverFile"
    echo "PearCommitID: $PEAR_COMMIT_ID"
else
    echo "Failed to patch server file: $serverFile"
    exit 1
fi

# ----------------------------

# Check if the productJsonFile exists
if [ ! -f "$productJsonFile" ]; then
    echo "Product JSON file not found: $productJsonFile"
    exit 1
fi

# patch the productJsonFile
sed -i "s/\"commit\": \"[^\"]*\"/\"commit\": \"$PEAR_COMMIT_ID\"/" "$productJsonFile"

# Check if the sed command was successful
if [ $? -eq 0 ]; then
    echo "Product JSON file successfully modified: $productJsonFile"
else
    echo "Failed to modify the Product JSON file: $productJsonFile"
    exit 1
fi

# ----------------------------

# Rename the server folder to PEAR_COMMIT_ID
if [ -d "$pearServerLocation/$VSC_COMMIT_ID" ]; then
    mv "$pearServerLocation/$VSC_COMMIT_ID" "$pearServerLocation/$PEAR_COMMIT_ID"
    if [ $? -eq 0 ]; then
        echo "Successfully renamed folder to $pearServerLocation/$PEAR_COMMIT_ID"
    else
        echo "Failed to rename folder"
        exit 1
    fi
else
    echo "Source folder $pearServerLocation/$VSC_COMMIT_ID does not exist"
    exit 1
fi

# ----------------------------

# Update variables to use the new folder name
serverFile="$pearServerLocation/$PEAR_COMMIT_ID/out/vs/server/node/server.main.js"
productJsonFile="$pearServerLocation/$PEAR_COMMIT_ID/product.json"
