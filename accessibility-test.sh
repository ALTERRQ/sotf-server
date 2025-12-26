#!/bin/sh
# Accessibility test (Client side)

set -e

SERVER_IP="${1:?Server IP required}"
PORT="${2:-8766}"
CLIENT_LISTEN_PORT=$((PORT + 10000))
LISTEN_TIMEOUT=15
SEND_TIMEOUT=5
MAX_RETRIES=3

echo "🔍 Accessibility test (Client side)"
echo "🤝 Performing UDP Handshake"
echo "=========================="
echo "Server: $SERVER_IP:$PORT"
echo "Client listening port: $CLIENT_LISTEN_PORT"
echo

if ! command -v ncat >/dev/null 2>&1; then
    echo "ERROR: Install ncat: apt-get install nmap"
    exit 1
fi

# Get client IP (for logging)
CLIENT_IP=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7}' | head -1)
[ -z "$CLIENT_IP" ] && CLIENT_IP="unknown"

echo "Client IP: $CLIENT_IP"
echo

# Cleanup function
cleanup() {
    rm -f /tmp/client_response.$$ 2>/dev/null
}

trap cleanup EXIT

# Perform handshake
perform_handshake() {
    echo "🔄 Initiating handshake..."

    # Step 1: Send SYN
    echo -n "  1. Sending SYN... "
    if echo "SYN:$CLIENT_IP:$(date +%s)" | \
        timeout "$SEND_TIMEOUT" ncat -u -w "$SEND_TIMEOUT" "$SERVER_IP" "$PORT" 2>/dev/null; then
        echo "✅"
    else
        echo "❌ (Send failed)"
        return 1
    fi

    # Step 2: Wait for SYN-ACK (listen on different port)
    echo -n "  2. Waiting for SYN-ACK... "
    if timeout "$LISTEN_TIMEOUT" ncat -u -l -p "$CLIENT_LISTEN_PORT" --recv-only 2>/dev/null | \
        tee /tmp/client_response.$$ | grep -q "SYN-ACK:"; then
        echo "✅"
        RESPONSE=$(cat /tmp/client_response.$$)
        echo "     Received: $RESPONSE"
    else
        echo "❌ (No response)"
        return 1
    fi

    # Step 3: Send DATA
    echo -n "  3. Sending DATA... "
    if echo "DATA:CLIENT_HELLO_$(date +%s)" | \
        timeout "$SEND_TIMEOUT" ncat -u -w "$SEND_TIMEOUT" "$SERVER_IP" "$PORT" 2>/dev/null; then
        echo "✅"
    else
        echo "❌ (Send failed)"
        return 1
    fi

    # Step 4: Wait for ACK
    echo -n "  4. Waiting for ACK... "
    if timeout "$LISTEN_TIMEOUT" ncat -u -l -p "$CLIENT_LISTEN_PORT" --recv-only 2>/dev/null | \
        tee /tmp/client_response.$$ | grep -q "ACK:"; then
        echo "✅"
        RESPONSE=$(cat /tmp/client_response.$$)
        echo "     Received: $RESPONSE"
    else
        echo "❌ (No response)"
        return 1
    fi

    # Step 5: Send FIN
    echo -n "  5. Sending FIN... "
    if echo "FIN:CLIENT_DONE_$(date +%s)" | \
        timeout "$SEND_TIMEOUT" ncat -u -w "$SEND_TIMEOUT" "$SERVER_IP" "$PORT" 2>/dev/null; then
        echo "✅"
    else
        echo "❌ (Send failed)"
        return 1
    fi

    # Step 6: Wait for FIN-ACK
    echo -n "  6. Waiting for FIN-ACK... "
    if timeout "$LISTEN_TIMEOUT" ncat -u -l -p "$CLIENT_LISTEN_PORT" --recv-only 2>/dev/null | \
        tee /tmp/client_response.$$ | grep -q "FIN-ACK:"; then
        echo "✅"
        RESPONSE=$(cat /tmp/client_response.$$)
        echo "     Received: $RESPONSE"
        return 0
    else
        echo "❌ (No response)"
        return 1
    fi
}

# Main execution with retries
HANDSHAKE_SUCCESS=false
RETRY_COUNT=0

while [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ] && [ "$HANDSHAKE_SUCCESS" = "false" ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))

    if [ "$RETRY_COUNT" -gt 1 ]; then
        echo
        echo "🔄 Retry attempt $RETRY_COUNT/$MAX_RETRIES..."
        echo
    fi

    if perform_handshake; then
        HANDSHAKE_SUCCESS=true
        break
    else
        if [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; then
            echo
            echo "⏳ Waiting 2 seconds before retry..."
            sleep 2
        fi
    fi
done

echo

if [ "$HANDSHAKE_SUCCESS" = "true" ]; then
    echo "🎉 Handshake successful!"
    echo "✅ Server $SERVER_IP:$PORT is accessible"
    echo
    echo "🎮 Game connection ready"
    echo "   Host: $SERVER_IP"
    echo "   Port: $PORT"
    exit 0
else
    echo "❌ Handshake failed after $RETRY_COUNT attempts"
    echo "⚠️  Possible issues:"
    echo "   • Server not running accessibility test"
    echo "   • Firewall blocking UDP port $PORT/$CLIENT_LISTEN_PORT"
    echo "   • Network connectivity problems"
    echo "   • Server IP address incorrect"
    echo "   • Other"
    exit 1
fi
