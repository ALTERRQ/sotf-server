#!/usr/bin/env sh
# Accessibility test (Server side)

set -e

# Define variables
PORT="${1:-8766}"
CLIENT_LISTEN_PORT=$((PORT + 10000))
MAX_HANDSHAKE_TRIALS=3
TIMEOUT=20
LISTEN_TIMEOUT=15
SEND_TIMEOUT=5
HANDSHAKE_TRY_COUNT=0
CLIENT_IP=""
HANDSHAKE_SUCCESS=false

echo "🔍 Accessibility test (Server side)"
echo "🤝 Performing UDP Handshake"
echo "=========================="
echo "Port: $PORT"
echo "Client expected port: $CLIENT_LISTEN_PORT"
echo "Timeout: ${TIMEOUT}s/try"
echo "Max tries: $MAX_HANDSHAKE_TRIALS"
echo

# Check for ncat
if ! command -v ncat >/dev/null 2>&1; then
    echo "ERROR: Package: ncat is missing from container"
    exit 1
fi

echo "📡 Listening for UDP handshake on port $PORT..."
echo "Expected sequence: SYN → DATA → FIN"
echo

handshake() {
    # Step 2: Send SYN-ACK
    echo "  2. Sending SYN-ACK..."
    if echo "SYN-ACK:$(date +%s)" | \
        timeout "$SEND_TIMEOUT" ncat -u -w "$SEND_TIMEOUT" "$CLIENT_IP" "$CLIENT_LISTEN_PORT" 2>/dev/null; then
        echo "  ✅ Sent SYN-ACK"
    else
        echo "  ❌ Failed to send SYN-ACK"
        HANDSHAKE_TRY_COUNT=$((HANDSHAKE_TRY_COUNT + 1))
        return 1
    fi

    # Step 3: Wait for DATA
    echo "  3. Waiting for DATA..."
    if timeout "$LISTEN_TIMEOUT" ncat -u -l -p "$PORT" --recv-only 2>/dev/null | grep -q "DATA:"; then
        echo "  ✅ Received DATA"
    else
        echo "  ❌ Timeout waiting for DATA"
        HANDSHAKE_TRY_COUNT=$((HANDSHAKE_TRY_COUNT + 1))
        return 1
    fi

    # Step 4: Send ACK
    echo "  4. Sending ACK..."
    if echo "ACK:$(date +%s)" | \
        timeout "$SEND_TIMEOUT" ncat -u -w "$SEND_TIMEOUT" "$CLIENT_IP" "$CLIENT_LISTEN_PORT" 2>/dev/null; then
        echo "  ✅ Sent ACK"
    else
        echo "  ❌ Failed to send ACK"
        HANDSHAKE_TRY_COUNT=$((HANDSHAKE_TRY_COUNT + 1))
        return 1
    fi

    # Step 5: Wait for FIN
    echo "  5. Waiting for FIN..."
    if timeout "$LISTEN_TIMEOUT" ncat -u -l -p "$PORT" --recv-only 2>/dev/null | grep -q "FIN:"; then
        echo "  ✅ Received FIN"
    else
        echo "  ❌ Timeout waiting for FIN"
        HANDSHAKE_TRY_COUNT=$((HANDSHAKE_TRY_COUNT + 1))
        return 1
    fi

    # Step 6: Send FIN-ACK
    echo "  6. Sending FIN-ACK..."
    if echo "FIN-ACK:$(date +%s)" | \
        timeout "$SEND_TIMEOUT" ncat -u -w "$SEND_TIMEOUT" "$CLIENT_IP" "$CLIENT_LISTEN_PORT" 2>/dev/null; then
        echo "  ✅ Sent FIN-ACK"
        echo "🎉 Handshake complete!"
        return 0
    else
        echo "  ❌ Failed to send FIN-ACK"
        HANDSHAKE_TRY_COUNT=$((HANDSHAKE_TRY_COUNT + 1))
        return 1
    fi
}

# Main loop
while [ "$HANDSHAKE_TRY_COUNT" -lt "$MAX_HANDSHAKE_TRIALS" ] && [ "$HANDSHAKE_SUCCESS" = "false" ]; do
    echo "⏳ Waiting for handshake to initiate (trial $((HANDSHAKE_TRY_COUNT + 1))/$MAX_HANDSHAKE_TRIALS)..."
    echo

    # Step 1: Wait for SYN
    echo "  1. Waiting for SYN..."

    if timeout "$TIMEOUT" ncat -u -l -p "$PORT" --recv-only 2>/dev/null | \
        grep "SYN:" > /tmp/syn_packet.$$; then

        # Read the captured packet
        packet=$(cat /tmp/syn_packet.$$)
        rm -f /tmp/syn_packet.$$

        # Parse client IP from SYN packet (format: SYN:IP:TIMESTAMP)
        CLIENT_IP=$(echo "$packet" | awk -F'[: ]' '{print $2}')

        echo "$(date '+%H:%M:%S') - Client detected: $CLIENT_IP"
        echo "🤝 Starting handshake..."
        echo "  ✅ Received SYN"

        # Continue with handshake
        if handshake; then
            echo "✅ Connection established with $CLIENT_IP"
            HANDSHAKE_SUCCESS=true
        else
            echo "⚠️ Handshake incomplete with $CLIENT_IP"
        fi

    else
        echo "  ❌ Timeout waiting for SYN"
        HANDSHAKE_TRY_COUNT=$((HANDSHAKE_TRY_COUNT + 1))
    fi

    echo
done

# Cleanup temp file
rm -f /tmp/syn_packet.$$

# Final results
echo "🏁 Test completed"

if [ "$HANDSHAKE_SUCCESS" = "true" ]; then
    echo "✅ Your server is accessible! 🎉🎉🎉"
    exit 0
else
    echo "❌ Server accessibility test failed"
    echo "   Tried $HANDSHAKE_TRY_COUNT times with no success"
    exit 1
fi
