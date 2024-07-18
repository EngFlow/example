#!/bin/bash
echo "Starting docker container test"
DATE=$(sudo docker run alpine date) 

if [[ ! -z "$DATE" ]] && date -d "$DATE" "+%Y-%m-%d" >/dev/null 2>&1; then
    echo "The \"$DATE\" from container is a valid date string in the yyyy-mm-dd format."
    exit 0
else
    echo "The \"$DATE\" from container is NOT a valid date string in the yyyy-mm-dd format."
    exit 1 # terminate and indicate error
fi
