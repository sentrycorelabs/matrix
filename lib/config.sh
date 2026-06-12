#!/usr/bin/env bash

# ─── Settings ────────────────────────────────────────────────────

random_port() {
    echo $(( RANDOM % 16384 + 49152 ))
}

validate_ports() {
    local input="$1"
    IFS=',' read -ra port_list <<< "$input"
    for p in "${port_list[@]}"; do
        p=$(echo "$p" | tr -d ' ')
        if ! [[ "$p" =~ ^[0-9]+$ ]] || (( p < 1 || p > 65535 )); then
            return 1
        fi
    done
    return 0
}

load_settings() {
    local settings_file=".matrix/settings.json"
    if [[ -f "$settings_file" ]]; then
        MATRIX_SSH=$(jq -r '.ssh // false' "$settings_file")
        MATRIX_CLAUDE_AUTH=$(jq -r '.claude_auth // false' "$settings_file")
        MATRIX_CODEX_AUTH=$(jq -r '.codex_auth // false' "$settings_file")
        MATRIX_PORTS=$(jq -r '.ports // empty' "$settings_file" 2>/dev/null)
        if [[ -z "$MATRIX_PORTS" ]]; then
            # Backwards compat: old settings used "port" (singular)
            MATRIX_PORTS=$(jq -r '.port // empty' "$settings_file" 2>/dev/null)
        fi
        if [[ -z "$MATRIX_PORTS" ]]; then
            MATRIX_PORTS="$(random_port)"
        fi
        MATRIX_RUNTIMES=$(jq -r '(.runtimes // []) | join(" ")' "$settings_file" 2>/dev/null || echo "")
        return 0
    fi
    return 1
}

save_settings() {
    mkdir -p .matrix

    # Build runtimes JSON array
    local runtimes_json="[]"
    if [[ -n "$MATRIX_RUNTIMES" ]]; then
        runtimes_json=$(echo "$MATRIX_RUNTIMES" | tr ' ' '\n' | jq -R . | jq -s .)
    fi

    jq -n \
        --argjson ssh "$MATRIX_SSH" \
        --argjson claude_auth "$MATRIX_CLAUDE_AUTH" \
        --argjson codex_auth "${MATRIX_CODEX_AUTH:-false}" \
        --arg ports "$MATRIX_PORTS" \
        --argjson runtimes "$runtimes_json" \
        '{ssh: $ssh, claude_auth: $claude_auth, codex_auth: $codex_auth, ports: $ports, runtimes: $runtimes}' \
        > .matrix/settings.json
}

run_setup() {
    msg "$CYAN" "First-time setup for this project"
    echo ""

    # Auto-detect runtimes
    local detected
    detected=$(detect_runtimes)
    if [[ -n "$detected" ]]; then
        msg "$GREEN" "Detected runtimes: $detected"
    else
        msg "$YELLOW" "No runtimes detected (base environment only)"
    fi
    MATRIX_RUNTIMES="$detected"

    printf "  Override detected runtimes? (available: ${AVAILABLE_RUNTIMES[*]}) [n]: "
    read -r ans
    case "$ans" in
        [yY]*)
            printf "  Runtimes (space-separated, e.g. 'node python'): "
            read -r custom_runtimes
            MATRIX_RUNTIMES="$custom_runtimes"
            ;;
    esac

    printf "  Map ~/.ssh into container? [y/N] "
    read -r ans
    case "$ans" in
        [yY]*) MATRIX_SSH=true ;;
        *)     MATRIX_SSH=false ;;
    esac

    printf "  Pass Claude Code auth into container? [y/N] "
    read -r ans
    case "$ans" in
        [yY]*) MATRIX_CLAUDE_AUTH=true ;;
        *)     MATRIX_CLAUDE_AUTH=false ;;
    esac

    printf "  Pass Codex auth into container? [y/N] "
    read -r ans
    case "$ans" in
        [yY]*) MATRIX_CODEX_AUTH=true ;;
        *)     MATRIX_CODEX_AUTH=false ;;
    esac

    local default_port
    default_port=$(random_port)
    printf "  Ports to expose (comma-separated) [%s]: " "$default_port"
    read -r ans
    if [[ -z "$ans" ]]; then
        MATRIX_PORTS="$default_port"
    else
        if validate_ports "$ans"; then
            MATRIX_PORTS="$ans"
        else
            msg "$YELLOW" "Invalid port(s), using random port $default_port"
            MATRIX_PORTS="$default_port"
        fi
    fi

    if [[ -f .gitignore ]] && ! grep -qx '.matrix' .gitignore && ! grep -qx '.matrix/' .gitignore; then
        printf "  Add .matrix to .gitignore? [Y/n] "
        read -r ans
        case "$ans" in
            [nN]*) ;;
            *)
                echo "" >> .gitignore
                echo ".matrix" >> .gitignore
                msg "$GREEN" "Added .matrix to .gitignore"
                ;;
        esac
    fi

    echo ""
    save_settings
    msg "$GREEN" "Saved to .matrix/settings.json"
}
