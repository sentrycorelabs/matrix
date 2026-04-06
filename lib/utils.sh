#!/usr/bin/env bash

# ─── Colors ──────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Messaging ───────────────────────────────────────────────────

msg() {
    local color="$1"
    shift
    printf "${color}${BOLD}[matrix]${NC} %s\n" "$*"
}

# ─── Helpers ─────────────────────────────────────────────────────

get_container_name() {
    echo "${CONTAINER_PREFIX}-${1:-$(basename "$(pwd)")}"
}
