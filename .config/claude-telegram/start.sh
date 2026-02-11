#!/bin/bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/claude-telegram"
source "$CONFIG_DIR/config.env"

NODE="/Users/sangil.mo/.local/share/mise/installs/node/22.22.0/bin/node"
N8N="/Users/sangil.mo/.local/share/mise/installs/node/22.22.0/bin/n8n"
CLOUDFLARED="/opt/homebrew/bin/cloudflared"

LOG_DIR="$CONFIG_DIR/logs"
mkdir -p "$LOG_DIR"

PID_DIR="$CONFIG_DIR/pids"
mkdir -p "$PID_DIR"

start_tunnel() {
  if [ -f "$PID_DIR/tunnel.pid" ] && kill -0 "$(cat "$PID_DIR/tunnel.pid")" 2>/dev/null; then
    echo "Tunnel already running (PID $(cat "$PID_DIR/tunnel.pid"))"
    return
  fi
  nohup "$CLOUDFLARED" tunnel --url "http://localhost:$N8N_PORT" > "$LOG_DIR/tunnel.log" 2>&1 &
  echo $! > "$PID_DIR/tunnel.pid"
  sleep 5
  WEBHOOK_URL=$(grep -o 'https://[^ ]*\.trycloudflare\.com' "$LOG_DIR/tunnel.log" | head -1)
  echo "$WEBHOOK_URL" > "$CONFIG_DIR/webhook_url"
  echo "Tunnel started: $WEBHOOK_URL"
}

start_api() {
  if [ -f "$PID_DIR/api.pid" ] && kill -0 "$(cat "$PID_DIR/api.pid")" 2>/dev/null; then
    echo "API server already running (PID $(cat "$PID_DIR/api.pid"))"
    return
  fi
  API_KEY="$API_KEY" API_PORT="$API_PORT" BOT_TOKEN="$BOT_TOKEN" nohup "$NODE" "$CONFIG_DIR/claude-api-server.js" > "$LOG_DIR/api.log" 2>&1 &
  echo $! > "$PID_DIR/api.pid"
  echo "API server started on port $API_PORT"
}

start_n8n() {
  if [ -f "$PID_DIR/n8n.pid" ] && kill -0 "$(cat "$PID_DIR/n8n.pid")" 2>/dev/null; then
    echo "n8n already running (PID $(cat "$PID_DIR/n8n.pid"))"
    return
  fi
  WEBHOOK_URL=$(cat "$CONFIG_DIR/webhook_url" 2>/dev/null || echo "")
  if [ -z "$WEBHOOK_URL" ]; then
    echo "ERROR: No webhook URL found. Start tunnel first."
    return 1
  fi
  WEBHOOK_URL="$WEBHOOK_URL" nohup "$NODE" "$N8N" start > "$LOG_DIR/n8n.log" 2>&1 &
  echo $! > "$PID_DIR/n8n.pid"
  echo "n8n started on port $N8N_PORT (webhook: $WEBHOOK_URL)"
}

stop_service() {
  local name=$1
  if [ -f "$PID_DIR/$name.pid" ]; then
    local pid=$(cat "$PID_DIR/$name.pid")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid"
      echo "$name stopped (PID $pid)"
    else
      echo "$name not running"
    fi
    rm -f "$PID_DIR/$name.pid"
  else
    echo "$name not running"
  fi
}

status_service() {
  local name=$1
  if [ -f "$PID_DIR/$name.pid" ] && kill -0 "$(cat "$PID_DIR/$name.pid")" 2>/dev/null; then
    echo "✓ $name running (PID $(cat "$PID_DIR/$name.pid"))"
  else
    echo "✗ $name stopped"
  fi
}

show_logs() {
  local service="${1:-all}"
  if [ "$service" = "all" ]; then
    for f in "$LOG_DIR"/*.log; do
      if [ -f "$f" ]; then
        echo "=== $(basename "$f") ==="
        tail -20 "$f"
        echo ""
      fi
    done
  else
    if [ -f "$LOG_DIR/$service.log" ]; then
      tail -50 "$LOG_DIR/$service.log"
    else
      echo "Log file not found: $LOG_DIR/$service.log"
    fi
  fi
}

case "${1:-help}" in
  start)
    start_tunnel
    start_api
    sleep 2
    start_n8n
    echo ""
    echo "All services started. Wait ~15s for n8n to be ready."
    ;;
  stop)
    stop_service n8n
    stop_service api
    stop_service tunnel
    ;;
  restart)
    "$0" stop
    sleep 3
    "$0" start
    ;;
  status)
    status_service tunnel
    status_service api
    status_service n8n
    if [ -f "$CONFIG_DIR/webhook_url" ]; then
      echo "Webhook: $(cat "$CONFIG_DIR/webhook_url")"
    fi
    ;;
  logs)
    show_logs "${2:-all}"
    ;;
  help|*)
    echo "Usage: $0 {start|stop|restart|status|logs [service]}"
    echo "Services: tunnel, api, n8n"
    ;;
esac
