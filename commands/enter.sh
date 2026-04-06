#!/usr/bin/env bash

cmd_enter() {
    local name=""
    local port_override=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -p) port_override="$2"; shift 2 ;;
            -n) name="$2"; shift 2 ;;
            *)  shift ;;
        esac
    done

    if ! load_settings; then
        run_setup
    fi

    local port="${port_override:-$MATRIX_PORT}"
    local container_name
    container_name=$(get_container_name "$name")

    # Reconnect to existing container
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        msg "$GREEN" "Reconnecting to ${container_name}..."
        docker exec -it "$container_name" /usr/bin/zsh
        return
    fi

    # Build docker run arguments
    local -a run_args
    build_run_args "$port" "$container_name"

    msg "$GREEN" "Entering the Matrix..."
    docker run "${run_args[@]}" "$IMAGE_NAME"
}
