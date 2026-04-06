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
    local port="$1"
    local container_name="$2"

    run_args=(
        --rm -it
        -v "$(pwd)":/app
        -v /var/run/docker.sock:/var/run/docker.sock
        -p "$port:$port"
        --name "$container_name"
    )

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
