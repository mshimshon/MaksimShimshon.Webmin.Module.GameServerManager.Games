#!/bin/bash

PATCH_FILE="/home/lgsm/blazor_lgsm/config_patch.cfg"

# Add as many folders as you want here:
INI_DIRS=(
    "/home/lgsm/lgsm/config-default/config-game"
    "/home/lgsm/Zomboid/Server"
)

# Check patch file
[ ! -f "$PATCH_FILE" ] && echo "Missing $PATCH_FILE" && exit 1

declare -A PATCHES

# --- Load config_patch.cfg ONCE ---
while IFS= read -r rawline; do
    
    line="$(echo "$rawline" | sed 's/^[ \t]*//;s/[ \t]*$//')"

    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^# ]] && continue

    line="${line%%#*}"
    line="$(echo "$line" | sed 's/^[ \t]*//;s/[ \t]*$//')"

    [[ "$line" != *"="* ]] && continue

    key="${line%%=*}"
    value="${line#*=}"

    key="$(echo "$key" | sed 's/^[ \t]*//;s/[ \t]*$//')"
    value="$(echo "$value" | sed 's/^[ \t]*//;s/[ \t]*$//')"

    PATCHES["$key"]="$value"

done < "$PATCH_FILE"

echo "Loaded ${#PATCHES[@]} constraints."

# --- Process each folder ---
for DIR in "${INI_DIRS[@]}"; do

    echo "Checking folder: $DIR"

    if [ ! -d "$DIR" ]; then
        echo "Skipping missing folder: $DIR"
        continue
    fi

    # Find INI files in this folder
    find "$DIR" -type f -name "*.ini" | while read -r ini; do
        echo "Patching $ini ..."

        for key in "${!PATCHES[@]}"; do
            value="${PATCHES[$key]}"

            esc_key=$(printf '%s' "$key" | sed 's/[]\/$*.^|[]/\\&/g')
            esc_val=$(printf '%s' "$value" | sed 's/[]\/$*.^|[]/\\&/g')

            if grep -qE "^$esc_key=" "$ini"; then
                sed -i "s/^$esc_key=.*/$esc_key=$esc_val/" "$ini"
            else
                echo "$key=$value" >> "$ini"
            fi
        done

    done

done

echo "Patch completed across all folders."
exit 0
