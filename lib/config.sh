#!/usr/bin/env bash

# ─── Settings ────────────────────────────────────────────────────

load_settings() {
    local settings_file=".matrix/settings.json"
    if [[ -f "$settings_file" ]]; then
        MATRIX_SSH=$(jq -r '.ssh // true' "$settings_file")
        MATRIX_CLAUDE_AUTH=$(jq -r '.claude_auth // true' "$settings_file")
        MATRIX_PORT=$(jq -r '.port // 5173' "$settings_file")
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
  "port": ${MATRIX_PORT}
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

    printf "  Default port [5173]: "
    read -r ans
    MATRIX_PORT=${ans:-5173}

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
