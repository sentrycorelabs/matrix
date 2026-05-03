#!/usr/bin/env bash

cmd_enter() {
    local name=""
    local ports_override=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -p)
                if validate_ports "$2"; then
                    ports_override="$2"
                else
                    msg "$RED" "Invalid port(s): $2"
                    return 1
                fi
                shift 2 ;;
            -n) name="$2"; shift 2 ;;
            *)  shift ;;
        esac
    done

    if ! load_settings; then
        run_setup
    fi

    # Show font notice once
    if [[ ! -f "$MATRIX_HOME/font_notice_shown" ]]; then
        echo ""
        msg "$CYAN" "Powerlevel10k works best with a Nerd Font."
        msg "$CYAN" "If icons look broken, install one from: https://www.nerdfonts.com"
        msg "$CYAN" "Any Nerd Font works (Meslo, Fira Code, JetBrains Mono, etc.)"
        echo ""
        touch "$MATRIX_HOME/font_notice_shown"
    fi

    local ports="${ports_override:-$MATRIX_PORTS}"
    local container_name
    container_name=$(get_container_name "$name")

    # Resolve and ensure the image exists
    local image_name
    image_name=$(ensure_image "$MATRIX_RUNTIMES")

    # Start new container if not already running
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        # Remove stopped container with same name if it exists
        docker rm "$container_name" 2>/dev/null

        local -a run_args
        build_run_args "$ports" "$container_name" "$image_name"

        msg "$GREEN" "Entering the Matrix..."
        docker run "${run_args[@]}" "$image_name" > /dev/null
    else
        msg "$GREEN" "Reconnecting to ${container_name}..."
    fi

    # Attach to shared tmux session (create if first connection)
    docker exec -it "$container_name" /usr/bin/zsh -c \
        'tmux has-session -t matrix 2>/dev/null && tmux attach -t matrix || tmux new-session -s matrix'
}
