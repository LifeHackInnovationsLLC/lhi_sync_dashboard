#!/usr/bin/env bash
#
# LHI Sync Dashboard - Launch Script
#
# Starts the sync status dashboard on the port from port_registry
#
# Usage:
#   ./launch.sh           # Start service
#   ./launch.sh stop      # Stop service
#   ./launch.sh status    # Check service status
#   ./launch.sh restart   # Restart service

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure LHI_SCRIPTS_ROOT is set
if [ -z "$LHI_SCRIPTS_ROOT" ]; then
    echo "Error: LHI_SCRIPTS_ROOT not set"
    exit 1
fi

# Source port registry for dynamic port lookup
source "${LHI_SCRIPTS_ROOT}/lhi_modules/lhi_git_projects/LifeHackInnovationsLLC/lhi_node_modules/lhi_bash_utilities/lib/port_registry.sh"
PORT=$(get_port_by_tool "lhi-sync-dashboard")

# PID file
PID_FILE="$SCRIPT_DIR/.sync-dashboard.pid"

# Log files
mkdir -p "$SCRIPT_DIR/logs"
LOG_FILE="$SCRIPT_DIR/logs/sync-dashboard.log"

#######################################
# Helper functions
#######################################
print_status() { echo -e "${BLUE}[Sync Dashboard]${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

check_port() {
  lsof -ti:$1 > /dev/null 2>&1
}

kill_port() {
  local port=$1
  local name=$2
  if check_port $port; then
    print_status "Stopping $name on port $port..."
    lsof -ti:$port | xargs kill -9 2>/dev/null || true
    sleep 1
    print_success "$name stopped"
  fi
}

#######################################
# Stop service
#######################################
stop_services() {
  print_status "Stopping Sync Dashboard..."

  # Kill by PID file
  if [ -f "$PID_FILE" ]; then
    local pid=$(cat "$PID_FILE")
    if ps -p $pid > /dev/null 2>&1; then
      kill $pid 2>/dev/null || true
      print_success "Sync Dashboard stopped (PID: $pid)"
    fi
    rm -f "$PID_FILE"
  fi

  # Also check port
  kill_port $PORT "Sync Dashboard"

  print_success "Service stopped"
}

#######################################
# Check status
#######################################
check_status() {
  print_status "Sync Dashboard Status"
  echo ""

  local running=false

  if [ -f "$PID_FILE" ]; then
    local pid=$(cat "$PID_FILE")
    if ps -p $pid > /dev/null 2>&1; then
      print_success "Sync Dashboard running (PID: $pid, Port: $PORT)"
      running=true
    else
      print_error "Sync Dashboard not running (stale PID file)"
      rm -f "$PID_FILE"
    fi
  elif check_port $PORT; then
    print_warning "Port $PORT in use (unknown process)"
  else
    print_error "Sync Dashboard not running"
  fi

  echo ""
  if [ "$running" = true ]; then
    print_success "Service running"
    echo ""
    echo -e "  ${BLUE}Dashboard:${NC} http://localhost:$PORT"
    echo ""
    echo -e "  ${BLUE}Logs:${NC} $LOG_FILE"
  else
    print_error "Service not running"
  fi
}

#######################################
# Start service
#######################################
start_services() {
  print_status "Starting Sync Dashboard"
  echo ""

  # Check for port conflicts - always clean restart
  if check_port $PORT; then
    print_warning "Port $PORT already in use - stopping..."
    kill_port $PORT "Sync Dashboard"
    print_status "Waiting for port to be released..."
    sleep 2
  fi

  # Check for node_modules
  if [ ! -d "$SCRIPT_DIR/node_modules" ]; then
    print_status "node_modules not found. Running npm install..."
    npm install
    print_success "Dependencies installed"
    echo ""
  fi

  # Start the server with PORT from registry
  print_status "Starting Sync Dashboard (port $PORT)..."
  PORT=$PORT node "$SCRIPT_DIR/server.js" > "$LOG_FILE" 2>&1 &
  SERVER_PID=$!
  echo $SERVER_PID > "$PID_FILE"

  sleep 2
  if ps -p $SERVER_PID > /dev/null 2>&1; then
    print_success "Sync Dashboard started (PID: $SERVER_PID)"
  else
    print_error "Sync Dashboard failed to start. Check logs: $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
  fi

  echo ""
  print_success "Service started successfully!"
  echo ""
  echo -e "  ${GREEN}Dashboard:${NC} http://localhost:$PORT"
  echo ""
  echo -e "  ${BLUE}Logs:${NC} tail -f $LOG_FILE"
  echo ""
  echo -e "  ${YELLOW}To stop:${NC} ./launch.sh stop"
  echo ""
}

#######################################
# Main
#######################################
case "${1:-start}" in
  start)
    start_services
    ;;
  stop)
    stop_services
    ;;
  restart)
    stop_services
    sleep 1
    start_services
    ;;
  status)
    check_status
    ;;
  logs)
    echo "Tailing logs (Ctrl+C to exit)..."
    tail -f "$LOG_FILE"
    ;;
  *)
    echo "LHI Sync Dashboard - Launch Script"
    echo ""
    echo "Usage: ./launch.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start       Start service (default)"
    echo "  stop        Stop service"
    echo "  restart     Restart service"
    echo "  status      Check service status"
    echo "  logs        Tail logs"
    echo ""
    exit 1
    ;;
esac
