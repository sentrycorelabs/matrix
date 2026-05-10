#!/usr/bin/env bash

cmd_update() {
    msg "$CYAN" "Updating the Matrix..."

    # Pull latest CLI
    git -C "$MATRIX_HOME" pull || { msg "$RED" "Failed to pull latest changes."; return 1; }

    # Pull latest images from GHCR
    ensure_base_image || return 1

    for rt in "${AVAILABLE_RUNTIMES[@]}"; do
        ensure_runtime_image "$rt" || return 1
    done

    # Invalidate local project images so they rebuild on next run
    docker images --format '{{.Repository}}:{{.Tag}}' | grep '^matrix-' | while read -r img; do
        docker rmi "$img" 2>/dev/null
    done

    msg "$GREEN" "Update complete. Project images will rebuild on next run."
}
