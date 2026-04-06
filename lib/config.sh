#!/usr/bin/env bash

# ─── Settings ────────────────────────────────────────────────────

load_settings() {
    local settings_file=".matrix/settings.json"
    if [[ -f "$settings_file" ]]; then
        MATRIX_SSH=$(jq -r '.ssh // true' "$settings_file")
        MATRIX_CLAUDE_AUTH=$(jq -r '.claude_auth // true' "$settings_file")
        MATRIX_PORTS=$(jq -r '.ports // "5173"' "$settings_file")
        return 0
    fi
    return 1
}

save_settings() {
    mkdir -p .matrix
    cat > .matrix/settings.json <<SETTINGS
{
  "ssh": ${MATRIX_SSH},
  "claude_auth": ${MATRIX_CLAUDE_AUTH},
  "ports": "${MATRIX_PORTS}"
}
SETTINGS
}

run_setup() {
    msg "$CYAN" "First-time setup for this project"
    echo ""

    printf "  Map ~/.ssh into container? [Y/n] "
    read -r ans
    case "$ans" in
        [nN]*) MATRIX_SSH=false ;;
        *)     MATRIX_SSH=true ;;
    esac

    printf "  Pass Claude Code auth into container? [Y/n] "
    read -r ans
    case "$ans" in
        [nN]*) MATRIX_CLAUDE_AUTH=false ;;
        *)     MATRIX_CLAUDE_AUTH=true ;;
    esac

    printf "  Ports to expose (comma-separated) [5173]: "
    read -r ans
    if [[ -z "$ans" ]]; then
        MATRIX_PORTS="5173"
    else
        local valid=true
        IFS=',' read -ra port_list <<< "$ans"
        for p in "${port_list[@]}"; do
            p=$(echo "$p" | tr -d ' ')
            if ! [[ "$p" =~ ^[0-9]+$ ]] || (( p < 1 || p > 65535 )); then
                valid=false
                break
            fi
        done
        if [[ "$valid" == "true" ]]; then
            MATRIX_PORTS="$ans"
        else
            msg "$YELLOW" "Invalid port(s), using default 5173"
            MATRIX_PORTS="5173"
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
