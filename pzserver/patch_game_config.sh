#!/bin/bash

PATCH_FILE="/home/lgsm/blazor_lgsm/config_patch.cfg"
INI_DIR="/home/lgsm/lgsm/config-default/config-game"

# Sanity checks
[ ! -f "$PATCH_FILE" ] && echo "Missing $PATCH_FILE" && exit 1
[ ! -d "$INI_DIR" ] && echo "Missing INI directory $INI_DIR" && exit 1

# Loop over all INI files
find "$INI_DIR" -type f -name "*.ini" | while read -r ini; do
    echo "Patching $ini ..."

    while IFS='=' read -r key value; do
        # Skip empty or comment lines
        [[ -z "$key" ]] && continue
        [[ "$key" =~ ^# ]] && continue

        # Escape sed special characters
        esc_key=$(printf '%s\n' "$key" | sed 's/[]\/$*.^|[]/\\&/g')
        esc_val=$(printf '%s\n' "$value" | sed 's/[]\/$*.^|[]/\\&/g')

        # Replace existing key OR append if missing
        if grep -qE "^$esc_key=" "$ini"; then
            sed -i "s/^$esc_key=.*/$esc_key=$esc_val/" "$ini"
        else
            echo "$key=$value" >> "$ini"
        fi
    done < "$PATCH_FILE"

done

echo "Patch completed."
exit 0
