#!/bin/bash
clean() {
    sed -r 's/\x1B\[[0-9;]*[mK]//g'
}
to_mb() {
    local raw="$1"
    local num=$(echo "$raw" | sed 's/[^0-9\.]//g')
    [ -z "$num" ] && echo "0" && return
    if echo "$raw" | grep -qiE 'tb$'; then awk "BEGIN {printf \"%d\", $num * 1024 * 1024}"
    elif echo "$raw" | grep -qiE 't$'; then awk "BEGIN {printf \"%d\", $num * 1024 * 1024}"
    elif echo "$raw" | grep -qiE 'gb$'; then awk "BEGIN {printf \"%d\", $num * 1024}"
    elif echo "$raw" | grep -qiE 'g$'; then awk "BEGIN {printf \"%d\", $num * 1024}"
    elif echo "$raw" | grep -qiE 'mb$'; then awk "BEGIN {printf \"%d\", $num}"
    elif echo "$raw" | grep -qiE 'm$'; then awk "BEGIN {printf \"%d\", $num}"
    elif echo "$raw" | grep -qiE 'kb$'; then awk "BEGIN {printf \"%d\", int($num / 1024)}"
    elif echo "$raw" | grep -qiE 'k$'; then awk "BEGIN {printf \"%d\", int($num / 1024)}"
    else awk "BEGIN {printf \"%d\", $num}"; fi
}

OUTPUT=$(/home/lgsm/pzserver details 2>&1 | clean)
GAME_INFO_FILE="/home/lgsm/blazor_lgsm/game_info.json"

CPU_MODEL=$(echo "$OUTPUT" | grep "Model:" | sed 's/Model:\s*//')
CPU_CORES=$(echo "$OUTPUT" | grep "Cores:" | awk '{print $2}')
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | sed 's/.*, *\([0-9.]*\)%* id.*/\1/')
CPU_USAGE=$(printf "%.0f" "$(echo "100 - $CPU_IDLE" | bc)")
STATUS=$(echo "$OUTPUT" | grep "Status:" | tail -1 | awk '{print $2}')

MEM_LINE=$(echo "$OUTPUT" | grep "Physical:")
MEM_TOTAL=$(to_mb "$(echo "$MEM_LINE" | awk '{print $2}')")
MEM_USED=$(to_mb "$(echo "$MEM_LINE" | awk '{print $3}')")
MEM_FREE=$(to_mb "$(echo "$MEM_LINE" | awk '{print $4}')")

STORAGE_TOTAL=$(to_mb "$(echo "$OUTPUT" | grep -A3 'Filesystem:' | grep 'Total:' | awk '{print $2}')")
STORAGE_USED=$(to_mb "$(echo "$OUTPUT" | grep -A3 'Filesystem:' | grep 'Used:' | awk '{print $2}')")
STORAGE_AVAIL=$(to_mb "$(echo "$OUTPUT" | grep -A3 'Filesystem:' | grep 'Available:' | awk '{print $2}')")

SERVER_NAME=$(echo "$OUTPUT" | grep "Server name:" | sed 's/Server name:\s*//')
SERVER_IP=$(echo "$OUTPUT" | grep "Server IP:" | awk '{print $3}' | cut -d: -f1)
SERVER_PORT=$(echo "$OUTPUT" | grep "Server IP:" | awk '{print $3}' | cut -d: -f2)
MAX_PLAYERS=$(echo "$OUTPUT" | grep "Maxplayers:" | awk '{print $2}')
CONFIG_FILE=$(echo "$OUTPUT" | grep "Config file:" | sed 's/Config file:\s*//')

# Check if game_info.json exists and is valid
GAME_INFO_JSON=""
if [ -f "$GAME_INFO_FILE" ] && jq empty "$GAME_INFO_FILE" 2>/dev/null; then
    GAME_INFO_JSON=$(cat "$GAME_INFO_FILE")
fi

# Build JSON conditionally
if [ -n "$GAME_INFO_JSON" ]; then
    cat << EOF
{
  "status": "$STATUS",
  "server": {
    "name": "$SERVER_NAME",
    "ip": "$SERVER_IP",
    "port": $SERVER_PORT,
    "max_players": $MAX_PLAYERS
  },
  "game_info": $GAME_INFO_JSON,
  "config_file": "$CONFIG_FILE",
  "resources": {
    "cpu": {
      "model": "$CPU_MODEL",
      "cores": $CPU_CORES,
      "usage": $CPU_USAGE
    },
    "memory": {
      "total": $MEM_TOTAL,
      "used": $MEM_USED,
      "free": $MEM_FREE
    },
    "storage": {
      "total": $STORAGE_TOTAL,
      "used": $STORAGE_USED,
      "available": $STORAGE_AVAIL
    }
  },
  "timestamp": "$(TZ=UTC date +'%Y-%m-%dT%H:%M:%SZ')"
}
EOF
else
    cat << EOF
{
  "status": "$STATUS",
  "server": {
    "name": "$SERVER_NAME",
    "ip": "$SERVER_IP",
    "port": $SERVER_PORT,
    "max_players": $MAX_PLAYERS
  },
  "config_file": "$CONFIG_FILE",
  "resources": {
    "cpu": {
      "model": "$CPU_MODEL",
      "cores": $CPU_CORES,
      "usage": $CPU_USAGE
    },
    "memory": {
      "total": $MEM_TOTAL,
      "used": $MEM_USED,
      "free": $MEM_FREE
    },
    "storage": {
      "total": $STORAGE_TOTAL,
      "used": $STORAGE_USED,
      "available": $STORAGE_AVAIL
    }
  },
  "timestamp": "$(TZ=UTC date +'%Y-%m-%dT%H:%M:%SZ')"
}
EOF
fi