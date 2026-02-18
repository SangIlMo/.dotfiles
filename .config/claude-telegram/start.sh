#!/bin/bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/claude-telegram"
source "$CONFIG_DIR/config.env"

NODE="$(which node)"
N8N="$(which n8n)"
CLOUDFLARED="$(which cloudflared)"

LOG_DIR="$CONFIG_DIR/logs"
mkdir -p "$LOG_DIR"

PID_DIR="$CONFIG_DIR/pids"
mkdir -p "$PID_DIR"

# Ensure a port is not occupied before starting a service.
# If the port is in use, kills the occupying process.
ensure_port_clear() {
  local port=$1
  local occupying_pid
  occupying_pid=$(lsof -ti tcp:"$port" 2>/dev/null || true)
  if [ -n "$occupying_pid" ]; then
    echo "Port $port is occupied by PID $occupying_pid — killing it..."
    kill "$occupying_pid" 2>/dev/null || true
    local waited=0
    while lsof -ti tcp:"$port" >/dev/null 2>&1; do
      sleep 0.5
      waited=$((waited + 1))
      if [ "$waited" -ge 6 ]; then
        echo "Port $port still occupied after 3s — sending SIGKILL to $occupying_pid"
        kill -9 "$occupying_pid" 2>/dev/null || true
        break
      fi
    done
    echo "Port $port is now clear."
  fi
}

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
  ensure_port_clear "$API_PORT"
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
  ensure_port_clear "$N8N_PORT"
  WEBHOOK_URL="$WEBHOOK_URL" nohup "$NODE" "$N8N" start > "$LOG_DIR/n8n.log" 2>&1 &
  echo $! > "$PID_DIR/n8n.pid"
  echo "n8n started on port $N8N_PORT (webhook: $WEBHOOK_URL)"
}

stop_service() {
  local name=$1
  local port="${2:-}"
  if [ -f "$PID_DIR/$name.pid" ]; then
    local pid
    pid=$(cat "$PID_DIR/$name.pid")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid"
      # Wait up to 3 seconds for process to exit gracefully
      local waited=0
      while kill -0 "$pid" 2>/dev/null; do
        sleep 0.5
        waited=$((waited + 1))
        if [ "$waited" -ge 6 ]; then
          echo "$name (PID $pid) did not exit after 3s — sending SIGKILL"
          kill -9 "$pid" 2>/dev/null || true
          break
        fi
      done
      echo "$name stopped (PID $pid)"
    else
      echo "$name not running"
    fi
    rm -f "$PID_DIR/$name.pid"
  else
    echo "$name not running"
  fi
  # Verify port is free if a port was specified
  if [ -n "$port" ]; then
    if lsof -ti tcp:"$port" >/dev/null 2>&1; then
      echo "WARNING: port $port still occupied after stopping $name — clearing it..."
      ensure_port_clear "$port"
    fi
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

# Wait for n8n to respond on /healthz, then print status.
# n8n manages its own webhook registration when WEBHOOK_URL is set and
# a Telegram trigger workflow is activated.
health_check() {
  local max_wait=30
  local waited=0
  echo "Waiting for n8n to be healthy (up to ${max_wait}s)..."
  while [ "$waited" -lt "$max_wait" ]; do
    if curl -sf "http://localhost:$N8N_PORT/healthz" >/dev/null 2>&1; then
      echo "n8n is healthy and ready."
      WEBHOOK_URL=$(cat "$CONFIG_DIR/webhook_url" 2>/dev/null || echo "")
      if [ -n "$WEBHOOK_URL" ]; then
        echo ""
        echo "Webhook base URL: $WEBHOOK_URL"
        # Note: the exact webhook path depends on your n8n Telegram trigger node
        # configuration. The default path used by n8n's Telegram trigger is typically
        # /webhook/telegram, but check your workflow's Webhook URL field to confirm.
        echo "Reminder: Activate your n8n workflow to register the Telegram webhook."
        echo "          n8n will automatically call setWebhook with the correct URL"
        echo "          when the workflow containing the Telegram trigger is activated."
      fi
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
  echo "WARNING: n8n did not respond on /healthz after ${max_wait}s."
  echo "         Check logs with: $0 logs n8n"
  return 1
}

case "${1:-help}" in
  start)
    # Stop first to ensure a clean slate (clears zombie processes / stale PIDs)
    echo "Stopping any existing services..."
    stop_service n8n "$N8N_PORT"
    stop_service api "$API_PORT"
    stop_service tunnel
    sleep 1
    echo ""
    echo "Starting services..."
    start_tunnel
    start_api
    sleep 2
    start_n8n
    echo ""
    health_check
    ;;
  stop)
    stop_service n8n "$N8N_PORT"
    stop_service api "$API_PORT"
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
