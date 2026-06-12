#!/usr/bin/env bash

cmd_list() {
    local ids
    ids=$(docker ps -q --filter "name=${CONTAINER_PREFIX}-")

    if [[ -z "$ids" ]]; then
        msg "$YELLOW" "No active Matrix containers. Run 'matrix start' in a project directory."
        return 0
    fi

    msg "$BLUE" "Active Matrix containers:"
    echo ""
    printf "  ${BOLD}%-22s %-16s %-14s %-22s %s${NC}\n" "NAME" "STATUS" "PORTS" "IMAGE" "PROJECT PATH"

    local id name status ports image path
    for id in $ids; do
        name=$(docker inspect -f '{{.Name}}' "$id" | sed 's|^/||')
        status=$(docker ps --filter "id=$id" --format '{{.Status}}')
        image=$(docker inspect -f '{{.Config.Image}}' "$id")

        # Project dir = bind mount source for /host (or /app pre-rename)
        path=$(docker inspect -f '{{range .Mounts}}{{if or (eq .Destination "/host") (eq .Destination "/app")}}{{.Source}}{{end}}{{end}}' "$id")
        [[ -z "$path" ]] && path="-"

        # Unique host ports, e.g. "3000,5173"
        ports=$(docker ps --filter "id=$id" --format '{{.Ports}}' \
            | grep -oE ':[0-9]+->' | tr -d ':>-' | sort -un | paste -sd ',' -)
        [[ -z "$ports" ]] && ports="-"

        printf "  ${CYAN}${BOLD}%-22s${NC} ${GREEN}%-16s${NC} ${YELLOW}%-14s${NC} %-22s ${BLUE}%s${NC}\n" \
            "$name" "$status" "$ports" "$image" "$path"
    done
    echo ""
}
