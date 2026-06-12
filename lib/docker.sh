#!/usr/bin/env bash

# ─── Claude Auth ─────────────────────────────────────────────────

get_claude_token() {
    local oauth_token=""
    local creds_json

    case "$MATRIX_PLATFORM" in
        macos)
            creds_json=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || echo "")
            ;;
        linux)
            if [[ -f "$HOME/.claude/.credentials.json" ]]; then
                creds_json=$(cat "$HOME/.claude/.credentials.json" 2>/dev/null || echo "")
            fi
            ;;
    esac

    if [[ -n "$creds_json" ]]; then
        oauth_token=$(echo "$creds_json" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null || echo "")
    fi
    echo "$oauth_token"
}

# ─── Run Args Builder ────────────────────────────────────────────

build_run_args() {
    local ports="$1"
    local container_name="$2"
    local image_name="$3"

    local project_name
    project_name=$(basename "$(pwd)")

    # Hostname from the project folder (sanitized: lowercase, RFC-safe chars)
    local hostname
    hostname=$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/^-*//; s/-*$//')
    [[ -z "$hostname" ]] && hostname="matrix"

    run_args=(
        -d
        --hostname "$hostname"
        -v "$(pwd)":/host
        -v /var/run/docker.sock:/var/run/docker.sock
        # Let bubblewrap create namespaces so Codex's sandbox works.
        # The docker.sock mount above is already host-root-equivalent,
        # so these grants don't meaningfully widen the blast radius.
        --security-opt seccomp=unconfined
        --cap-add SYS_ADMIN
        --name "$container_name"
    )

    # Isolate platform-specific dependency directories
    if [[ -f "$(pwd)/package.json" ]]; then
        run_args+=(-v "matrix-${project_name}-node_modules:/host/node_modules")
    fi
    if [[ -f "$(pwd)/composer.json" ]]; then
        run_args+=(-v "matrix-${project_name}-vendor:/host/vendor")
    fi

    # Map each port
    IFS=',' read -ra port_list <<< "$ports"
    for p in "${port_list[@]}"; do
        p=$(echo "$p" | tr -d ' ')
        run_args+=(-p "$p:$p")
    done

    # SSH
    if [[ "$MATRIX_SSH" == "true" ]]; then
        if [[ -d "$HOME/.ssh" ]]; then
            run_args+=(-v "$HOME/.ssh:/root/.ssh:ro")
        fi
    fi

    # Claude auth
    if [[ "$MATRIX_CLAUDE_AUTH" == "true" ]]; then
        local oauth_token
        oauth_token=$(get_claude_token)

        if [[ -d "$HOME/.claude" ]]; then
            run_args+=(-v "$HOME/.claude:/root/.claude:ro")
        fi
        if [[ -f "$HOME/.claude.json" ]]; then
            run_args+=(-v "$HOME/.claude.json:/root/.claude.json:ro")
        fi
        if [[ -n "$oauth_token" ]]; then
            run_args+=(-e "CLAUDE_CODE_OAUTH_TOKEN=${oauth_token}")
        fi
    fi

    # Codex auth — ~/.codex holds auth.json (and config); mounted read-write
    # so token refreshes inside the container persist to the host
    if [[ "$MATRIX_CODEX_AUTH" == "true" ]]; then
        if [[ -d "$HOME/.codex" ]]; then
            run_args+=(-v "$HOME/.codex:/root/.codex")
        else
            msg "$YELLOW" "~/.codex not found on host — run 'codex login' on the host first."
        fi
    fi
}
