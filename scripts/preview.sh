#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-4000}"
LIVERELOAD_PORT="${LIVERELOAD_PORT:-35729}"
BUNDLE_BIN="${BUNDLE_BIN:-/opt/homebrew/opt/ruby@3.3/bin/bundle}"
PID_FILE="$ROOT_DIR/.jekyll-preview.pid"
LOG_FILE="$ROOT_DIR/.jekyll-preview.log"

usage() {
  cat <<USAGE
Usage: scripts/preview.sh [start|foreground|stop|restart|status|logs]

Environment overrides:
  HOST=127.0.0.1
  PORT=4000
  LIVERELOAD_PORT=35729
  BUNDLE_BIN=/opt/homebrew/opt/ruby@3.3/bin/bundle
USAGE
}

is_running() {
  [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

port_pid() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null | head -n 1
  fi
}

stop_server() {
  if is_running; then
    local pid
    pid="$(cat "$PID_FILE")"
    echo "Stopping preview server pid=$pid"
    kill "$pid" 2>/dev/null || true
    for _ in {1..30}; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.2
    done
    kill -9 "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
    return
  fi

  local existing_pid existing_cmd
  existing_pid="$(port_pid || true)"
  if [[ -n "$existing_pid" ]]; then
    existing_cmd="$(ps -p "$existing_pid" -o command= 2>/dev/null || true)"
    if [[ "$existing_cmd" == *jekyll* && "$existing_cmd" == *"$ROOT_DIR"* ]]; then
      echo "Stopping preview server on port $PORT pid=$existing_pid"
      kill "$existing_pid" 2>/dev/null || true
      rm -f "$PID_FILE"
      return
    fi

    echo "Port $PORT is in use by pid=$existing_pid, but it was not started by this project."
    echo "Command: $existing_cmd"
    exit 1
  fi

  rm -f "$PID_FILE"
  echo "No preview server recorded."
}

start_server() {
  if is_running; then
    echo "Preview server is already running: http://$HOST:$PORT/"
    echo "pid=$(cat "$PID_FILE")"
    return
  fi

  local existing_pid
  existing_pid="$(port_pid || true)"
  if [[ -n "$existing_pid" ]]; then
    echo "Port $PORT is already in use by pid=$existing_pid."
    echo "Stop that process first, or run: PORT=4001 scripts/preview.sh start"
    exit 1
  fi

  if [[ ! -x "$BUNDLE_BIN" ]]; then
    echo "Bundle executable not found: $BUNDLE_BIN"
    exit 1
  fi

  cd "$ROOT_DIR"
  : > "$LOG_FILE"
  echo "Starting preview server at http://$HOST:$PORT/"
  echo "Log: $LOG_FILE"

  nohup env JEKYLL_ENV=development "$BUNDLE_BIN" exec jekyll serve \
    --host "$HOST" \
    --port "$PORT" \
    --livereload \
    --livereload-port "$LIVERELOAD_PORT" \
    --incremental \
    > "$LOG_FILE" 2>&1 &

  echo $! > "$PID_FILE"
  sleep 1

  if ! is_running; then
    echo "Preview server failed to start. Recent log:"
    tail -n 80 "$LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
  fi

  echo "Preview server is running: http://$HOST:$PORT/"
  echo "After edits, Jekyll rebuilds automatically. Refresh the browser if LiveReload is not active."
}

foreground_server() {
  local existing_pid
  existing_pid="$(port_pid || true)"
  if [[ -n "$existing_pid" ]]; then
    echo "Port $PORT is already in use by pid=$existing_pid."
    echo "Run scripts/preview.sh stop first, or use another port:"
    echo "  PORT=4001 scripts/preview.sh foreground"
    exit 1
  fi

  if [[ ! -x "$BUNDLE_BIN" ]]; then
    echo "Bundle executable not found: $BUNDLE_BIN"
    exit 1
  fi

  cd "$ROOT_DIR"
  echo "Serving preview at http://$HOST:$PORT/"
  echo "Jekyll will rebuild after edits. Press ctrl-c to stop."

  exec env JEKYLL_ENV=development "$BUNDLE_BIN" exec jekyll serve \
    --host "$HOST" \
    --port "$PORT" \
    --livereload \
    --livereload-port "$LIVERELOAD_PORT" \
    --incremental
}

status_server() {
  if is_running; then
    echo "Preview server is running: http://$HOST:$PORT/"
    echo "pid=$(cat "$PID_FILE")"
  else
    local existing_pid
    existing_pid="$(port_pid || true)"
    if [[ -n "$existing_pid" ]]; then
      echo "Port $PORT is occupied by pid=$existing_pid."
      ps -p "$existing_pid" -o pid,ppid,command
      return
    fi

    rm -f "$PID_FILE"
    echo "Preview server is not running."
  fi
}

case "${1:-start}" in
  start)
    start_server
    ;;
  foreground|serve)
    foreground_server
    ;;
  stop)
    stop_server
    ;;
  restart)
    stop_server
    start_server
    ;;
  status)
    status_server
    ;;
  logs)
    touch "$LOG_FILE"
    tail -n 120 -f "$LOG_FILE"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac
