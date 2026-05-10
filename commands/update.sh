#!/usr/bin/env bash

cmd_update() {
    msg "$CYAN" "Updating the Matrix..."

    # Pull latest CLI
    git -C "$MATRIX_HOME" pull || { msg "$RED" "Failed to pull latest changes."; return 1; }

    # Pull latest images from GHCR
    msg "$CYAN" "Pulling latest base image..."
    docker pull "${MATRIX_REGISTRY}:base"

    for rt in "${AVAILABLE_RUNTIMES[@]}"; do
        msg "$CYAN" "Pulling latest ${rt} runtime..."
        docker pull "${MATRIX_REGISTRY}:runtime-${rt}" 2>/dev/null || true
    done

    # Invalidate local project images so they rebuild on next run
    docker images --format '{{.Repository}}:{{.Tag}}' | grep '^matrix-' | while read -r img; do
        docker rmi "$img" 2>/dev/null
    done

    msg "$GREEN" "Update complete. Project images will rebuild on next run."
}
