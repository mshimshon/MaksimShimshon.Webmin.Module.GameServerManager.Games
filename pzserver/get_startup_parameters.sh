#!/bin/bash

# Script to print startup parameters JSON

STARTUP_PARAMS_FILE="/home/lgsm/blazor_lgsm/user_startup_parameters.json"

# Check if file exists or is empty
if [ ! -f "$STARTUP_PARAMS_FILE" ] || [ ! -s "$STARTUP_PARAMS_FILE" ]; then
    echo "[]"
    exit 0
fi

# Print compact JSON
cat "$STARTUP_PARAMS_FILE"

exit 0