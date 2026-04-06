#!/usr/bin/env bash

cmd_enter() {
    local name=""
    local ports_override=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -p)
                local valid=true
                IFS=',' read -ra _ports <<< "$2"
                for p in "${_ports[@]}"; do
                    p=$(echo "$p" | tr -d ' ')
                    if ! [[ "$p" =~ ^[0-9]+$ ]] || (( p < 1 || p > 65535 )); then
                        valid=false
                        break
                    fi
                done
                if [[ "$valid" == "true" ]]; then
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

    local ports="${ports_override:-$MATRIX_PORTS}"
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
    build_run_args "$ports" "$container_name"

    msg "$GREEN" "Entering the Matrix..."
    docker run "${run_args[@]}" "$IMAGE_NAME"
}
