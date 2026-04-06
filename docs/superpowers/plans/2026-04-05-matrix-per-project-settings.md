# Matrix Per-Project Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-project `.matrix/settings.json` with first-run interactive setup, replacing emojis with colored output.

**Architecture:** The `matrix` shell script gets new functions for settings I/O (`load_settings`, `save_settings`, `run_setup`) and colored output helpers. On first run in a directory, an interactive setup writes `.matrix/settings.json`. Subsequent runs read that file silently. The `docker run` command is built dynamically from settings. `jq` is used for JSON read/write (already available on macOS).

**Tech Stack:** Zsh, jq, ANSI escape codes

---

## File Structure

- **Modify:** `matrix` — the entire CLI script (colors, setup flow, conditional mounts, new `config` subcommand)
- **Delete:** `matrix.save` — editor backup, not needed
- **Modify:** `.gitignore` — add `*.save` to prevent future editor backups

Per-project (created at runtime, not committed):
- **Create:** `<project-dir>/.matrix/settings.json` — written by `run_setup`

---

### Task 1: Cleanup

**Files:**
- Delete: `matrix.save`
- Modify: `.gitignore`
- Modify: `matrix:95` (remove stray `B`)

- [ ] **Step 1: Delete `matrix.save`**

```bash
rm matrix.save
```

- [ ] **Step 2: Add `*.save` to `.gitignore`**

Append under the `# Editor` section:

```
*.save
```

- [ ] **Step 3: Remove stray `B` on line 95 of `matrix`**

Line 95 currently reads `B` — delete it entirely.

- [ ] **Step 4: Verify**

```bash
test ! -f matrix.save && echo "PASS: matrix.save deleted"
grep -q '*.save' .gitignore && echo "PASS: *.save in gitignore"
tail -3 matrix  # Should end with `esac` and nothing after
```

- [ ] **Step 5: Commit**

```bash
git add matrix matrix.save .gitignore
git commit -m "chore: remove matrix.save backup and stray character"
```

---

### Task 2: Replace emojis with ANSI color output

**Files:**
- Modify: `matrix` — top of file (add color vars + `msg` function), all `echo` statements throughout

- [ ] **Step 1: Add color variables and `msg` helper at top of script (after the variable declarations)**

```zsh
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

msg() {
    local color="$1"
    shift
    printf "${color}${BOLD}[matrix]${NC} %s\n" "$*"
}
```

- [ ] **Step 2: Replace every emoji echo with `msg` calls**

| Old | New |
|-----|-----|
| `echo "⚡ Reconnecting to ${container_name}..."` | `msg "$GREEN" "Reconnecting to ${container_name}..."` |
| `echo "🟢 Entering the Matrix..."` | `msg "$GREEN" "Entering the Matrix..."` |
| `echo "🔨 Building the Matrix..."` | `msg "$YELLOW" "Building the Matrix..."` |
| `echo "🔴 Exiting the Matrix: ${container_name}..."` | `msg "$RED" "Exiting the Matrix: ${container_name}..."` |
| `echo "🔵 Active Matrix containers:"` | `msg "$BLUE" "Active Matrix containers:"` |
| `echo "💀 Destroying the Matrix image..."` | `msg "$RED" "Destroying the Matrix image..."` |

- [ ] **Step 3: Verify**

```bash
grep -c emoji matrix  # Should be 0 (no emoji left)
zsh matrix help       # Should print usage without emojis
```

- [ ] **Step 4: Commit**

```bash
git add matrix
git commit -m "style: replace emojis with ANSI-colored output"
```

---

### Task 3: Settings load/save/setup functions

**Files:**
- Modify: `matrix` — add `load_settings`, `save_settings`, `run_setup` functions

- [ ] **Step 1: Add `load_settings` function**

Reads `.matrix/settings.json` from the current directory. Sets shell variables from JSON keys. Falls back to defaults if file is missing.

```zsh
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
```

- [ ] **Step 2: Add `save_settings` function**

```zsh
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
```

- [ ] **Step 3: Add `run_setup` function**

Interactive prompts with colored output. Defaults in brackets. Detects `.gitignore` and offers to add `.matrix` to it.

```zsh
run_setup() {
    msg "$CYAN" "First-time setup for this project"
    echo ""

    # SSH
    printf "  Map ~/.ssh into container? [Y/n] "
    read -r ans
    case "$ans" in
        [nN]*) MATRIX_SSH=false ;;
        *)     MATRIX_SSH=true ;;
    esac

    # Claude auth
    printf "  Pass Claude Code auth into container? [Y/n] "
    read -r ans
    case "$ans" in
        [nN]*) MATRIX_CLAUDE_AUTH=false ;;
        *)     MATRIX_CLAUDE_AUTH=true ;;
    esac

    # Port
    printf "  Default port [5173]: "
    read -r ans
    MATRIX_PORT=${ans:-5173}

    # .gitignore
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
```

- [ ] **Step 4: Verify functions parse correctly**

```bash
zsh -n matrix  # Syntax check — should produce no output
```

- [ ] **Step 5: Commit**

```bash
git add matrix
git commit -m "feat: add settings load/save/setup functions"
```

---

### Task 4: Wire settings into `cmd_enter` and add `config` subcommand

**Files:**
- Modify: `matrix` — rewrite `cmd_enter` to use settings, add `config` case

- [ ] **Step 1: Rewrite `cmd_enter` to call setup on first run and build docker args from settings**

At the start of `cmd_enter`, load settings or run setup if none exist. CLI flags (`-p`, `-n`) still override saved values. Build the `docker run` command dynamically:

```zsh
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

    # Load or create settings
    if ! load_settings; then
        run_setup
    fi

    local port="${port_override:-$MATRIX_PORT}"
    local container_name=$(get_container_name "$name")

    # Reconnect if already running
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        msg "$GREEN" "Reconnecting to ${container_name}..."
        docker exec -it "$container_name" /usr/bin/zsh
        return
    fi

    # Build docker run arguments
    local -a run_args=(
        --rm -it
        -v "$(pwd)":/app
        -v /var/run/docker.sock:/var/run/docker.sock
        -p "$port:$port"
        --name "$container_name"
    )

    # SSH mount
    if [[ "$MATRIX_SSH" == "true" ]]; then
        run_args+=(-v "$HOME/.ssh:/root/.ssh:ro")
    fi

    # Claude Code auth
    if [[ "$MATRIX_CLAUDE_AUTH" == "true" ]]; then
        local oauth_token=""
        local creds_json
        creds_json=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || echo "")
        if [[ -n "$creds_json" ]]; then
            oauth_token=$(echo "$creds_json" | python3 -c "import sys,json; print(json.load(sys.stdin)['claudeAiOauth']['accessToken'])" 2>/dev/null || echo "")
        fi
        run_args+=(
            -v "$HOME/.claude:/root/.claude"
            -v "$HOME/.claude.json:/root/.claude.json"
            -e "CLAUDE_CODE_OAUTH_TOKEN=${oauth_token:-}"
        )
    fi

    msg "$GREEN" "Entering the Matrix..."
    docker run "${run_args[@]}" "$IMAGE_NAME"
}
```

- [ ] **Step 2: Add `config` to the case statement**

```zsh
case "${1:-}" in
    build)   cmd_build ;;
    stop)    cmd_stop "$2" ;;
    list)    cmd_list ;;
    destroy) cmd_destroy ;;
    config)  run_setup ;;
    help|-h) usage ;;
    *)       cmd_enter "$@" ;;
esac
```

- [ ] **Step 3: Add `config` to the `usage` function**

Add this line to the commands list:

```
echo "  config      Re-run setup for the current directory"
```

- [ ] **Step 4: Verify**

```bash
zsh -n matrix           # Syntax check
zsh matrix help         # Should show config in usage
```

- [ ] **Step 5: Commit**

```bash
git add matrix
git commit -m "feat: wire per-project settings into container launch and add config subcommand"
```

---

### Task 5: Manual end-to-end verification

- [ ] **Step 1: Test first-run setup in a temp directory**

```bash
cd /tmp && mkdir matrix-test && cd matrix-test
git init && echo "node_modules" > .gitignore
/Users/jadchartouni/Matrix/matrix
# Should prompt for SSH, Claude auth, port, .gitignore
# Answer all defaults, verify .matrix/settings.json is created
# Ctrl-D to exit container
cat .matrix/settings.json
```

- [ ] **Step 2: Test subsequent run skips setup**

```bash
cd /tmp/matrix-test
/Users/jadchartouni/Matrix/matrix
# Should NOT prompt — goes straight to container
```

- [ ] **Step 3: Test `matrix config` re-runs setup**

```bash
cd /tmp/matrix-test
/Users/jadchartouni/Matrix/matrix config
# Should prompt again and overwrite settings
```

- [ ] **Step 4: Test without .gitignore**

```bash
cd /tmp && mkdir matrix-test-2 && cd matrix-test-2
/Users/jadchartouni/Matrix/matrix
# Should NOT ask about .gitignore
```

- [ ] **Step 5: Cleanup**

```bash
rm -rf /tmp/matrix-test /tmp/matrix-test-2
```

- [ ] **Step 6: Final commit if any fixes were needed**
