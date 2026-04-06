#!/usr/bin/env bash

cmd_build() {
    msg "$YELLOW" "Building the Matrix..."
    docker build -t "$IMAGE_NAME" "$MATRIX_HOME"
}
