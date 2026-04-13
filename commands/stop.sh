#!/usr/bin/env bash

cmd_stop() {
    local container_name
    container_name=$(get_container_name "$1")
    msg "$RED" "Exiting the Matrix: ${container_name}..."
    docker rm -f "$container_name" 2>/dev/null || echo "Container not running."
}
