#!/usr/bin/env bash

cmd_update() {
    msg "$CYAN" "Updating the Matrix..."
    git -C "$MATRIX_HOME" pull || { msg "$RED" "Failed to pull latest changes."; return 1; }
    cmd_build
}
