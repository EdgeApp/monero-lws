#!/bin/bash

# monero-lws-client launch script
# Connects to monerolws-s1-wusa1.edge.app

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration file path (default to same directory as script)
CONFIG_FILE="${CONFIG_FILE:-${SCRIPT_DIR}/lwsclient.conf}"

# Binary path (default to build directory, adjust if needed)
CLIENT_BINARY="${CLIENT_BINARY:-${SCRIPT_DIR}/../build/src/monero-lws-client}"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    echo "Please create the config file or set CONFIG_FILE environment variable"
    exit 1
fi

# Check if binary exists
if [ ! -f "$CLIENT_BINARY" ] && ! command -v "$CLIENT_BINARY" &> /dev/null; then
    echo "Error: Client binary not found: $CLIENT_BINARY"
    echo "Please build the client or set CLIENT_BINARY environment variable"
    exit 1
fi

# Launch the client
echo "Starting monero-lws-client..."
echo "Config file: $CONFIG_FILE"
echo "Server: monerolws-s1-wusa1.edge.app"
echo ""

exec "$CLIENT_BINARY" --config-file "$CONFIG_FILE" "$@"


