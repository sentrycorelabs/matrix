#!/usr/bin/env bash

cmd_destroy() {
    msg "$RED" "Destroying Matrix images..."

    # Remove local project images
    docker images --format '{{.Repository}}:{{.Tag}}' | grep '^matrix-' | while read -r img; do
        docker rmi "$img" 2>/dev/null
    done

    # Remove cached GHCR images
    docker images --format '{{.Repository}}:{{.Tag}}' | grep "^${MATRIX_REGISTRY}" | while read -r img; do
        docker rmi "$img" 2>/dev/null
    done

    msg "$GREEN" "Done."
}
