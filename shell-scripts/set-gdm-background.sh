#!/bin/bash
set -euo pipefail

#Setup GDM background, assumes your background image has been passed as the first argument to the script.
echo "----> Setting up GDM background based on if image was passed to script."
if [ -f "$1" ]; then
    convert $1 -filter Gaussian -blur 0x50 ./background-blur.jpg
    wget github.com/thiggy01/change-gdm-background/raw/master/change-gdm-background &> /dev/null
    chmod +x change-gdm-background
    ./change-gdm-background ./background-blur.jpg
fi
