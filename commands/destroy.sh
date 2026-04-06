#!/usr/bin/env bash

cmd_destroy() {
    msg "$RED" "Destroying the Matrix image..."
    docker rmi "$IMAGE_NAME" 2>/dev/null || echo "Image not found."
}
