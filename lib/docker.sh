#!/usr/bin/env bash

# ─── Claude Auth ─────────────────────────────────────────────────

get_claude_token() {
    local oauth_token=""
    local creds_json
    creds_json=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || echo "")
    if [[ -n "$creds_json" ]]; then
        oauth_token=$(echo "$creds_json" | python3 -c "import sys,json; print(json.load(sys.stdin)['claudeAiOauth']['accessToken'])" 2>/dev/null || echo "")
    fi
    echo "$oauth_token"
}

# ─── Run Args Builder ────────────────────────────────────────────

build_run_args() {
    local ports="$1"
    local container_name="$2"

    # Project name for named volumes
    local project_name
    project_name=$(basename "$(pwd)")

    run_args=(
        --rm -it
        -v "$(pwd)":/app
        -v /var/run/docker.sock:/var/run/docker.sock
        --name "$container_name"
    )

    # Isolate platform-specific dependency directories
    # This prevents macOS-installed binaries from conflicting with Linux
    if [[ -f "$(pwd)/package.json" ]]; then
        run_args+=(-v "matrix-${project_name}-node_modules:/app/node_modules")
    fi
    if [[ -f "$(pwd)/composer.json" ]]; then
        run_args+=(-v "matrix-${project_name}-vendor:/app/vendor")
    fi

    # Map each port
    IFS=',' read -ra port_list <<< "$ports"
    for p in "${port_list[@]}"; do
        p=$(echo "$p" | tr -d ' ')
        run_args+=(-p "$p:$p")
    done

    # SSH
    if [[ "$MATRIX_SSH" == "true" ]]; then
        run_args+=(-v "$HOME/.ssh:/root/.ssh:ro")
    fi

    # Claude auth
    if [[ "$MATRIX_CLAUDE_AUTH" == "true" ]]; then
        local oauth_token
        oauth_token=$(get_claude_token)

        run_args+=(
            -v "$HOME/.claude:/root/.claude"
            -v "$HOME/.claude.json:/root/.claude.json"
            -e "CLAUDE_CODE_OAUTH_TOKEN=${oauth_token:-}"
        )
    fi
}
