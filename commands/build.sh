#!/usr/bin/env bash

cmd_build() {
    if ! load_settings; then
        msg "$YELLOW" "No settings found. Run 'matrix start' first to set up this project."
        return 1
    fi

    local image_name
    image_name=$(get_image_name "$MATRIX_RUNTIMES")

    # Remove existing local image to force rebuild
    if [[ -n "$MATRIX_RUNTIMES" ]]; then
        docker rmi "$image_name" 2>/dev/null
    fi

    msg "$YELLOW" "Rebuilding project image..."
    if ! ensure_image "$MATRIX_RUNTIMES" > /dev/null; then
        return 1
    fi
    msg "$GREEN" "Done."
}
