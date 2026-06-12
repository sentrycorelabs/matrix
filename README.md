# Matrix

A portable, containerized development environment. One command drops you into a fully configured shell with your preferred tools, languages, and editor — on any machine with Docker.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/sentrycorelabs/matrix/main/install.sh | sh
```

This clones the repo to `~/.matrix/` and symlinks the CLI to `/usr/local/bin/matrix`. No image build needed — images are pulled automatically on first run.

**Requirements:** Docker and Git.
**Platforms:** macOS and Linux.

## What's Inside

**Shell & Terminal**
- Zsh with Oh My Zsh
- Powerlevel10k prompt
- zsh-autosuggestions & zsh-syntax-highlighting
- Tmux with vi-mode, TPM, session persistence (resurrect + continuum)

**Editor**
- Neovim with Lazy.nvim plugin management

**CLI Tools**
- ripgrep, fd, bat, jq, git, curl, wget, make, gcc/g++

**AI**
- Claude Code (with optional OAuth passthrough from macOS Keychain)
- Codex CLI (with optional `~/.codex` auth passthrough)

**Docker**
- Docker CLI + Compose plugin (talks to the host daemon via socket mount)

**Language Runtimes (auto-detected)**
- Node.js 22 — detected from `package.json`, `yarn.lock`, `pnpm-lock.yaml`, `.nvmrc`
- Python 3 — detected from `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile`, `.python-version`
- PHP 8.5 + Composer — detected from `composer.json`, `artisan`

All images are based on Ubuntu 26.04 LTS.

Only the runtimes your project needs are installed. No project files? You get the base environment. Need a runtime later? Install it from inside the container:

```bash
runtime add node      # or python, php
runtime add all       # everything
runtime list          # see what's installed
```

Installs take effect immediately in the running container and are saved to `.matrix/settings.json`, so the next image rebuild includes them.

## Usage

```
matrix <command> [options]

Commands:
  start        Enter the Matrix in the current directory
  build        Rebuild the project image
  stop [name]  Stop a running container (default: current dir)
  list         List running Matrix containers
  destroy      Remove all Matrix images
  config       Re-run setup for the current directory
  update       Pull latest images and CLI
  help         Show usage info (also shown when run with no command)

Options (for start):
  -p PORTS     Expose ports, comma-separated (default: random)
  -n NAME      Custom container name
```

### Examples

```bash
# Enter the Matrix in your current project directory
matrix start

# Enter with a custom port
matrix start -p 3000

# Enter with multiple ports
matrix start -p 3000,5173,8080

# Enter with a custom container name
matrix start -n api-project

# Reconnect to a running container (automatic — just run matrix start again)
matrix start

# List all active containers
matrix list

# Stop a specific container
matrix stop api-project

# Update Matrix to the latest version
matrix update

# Re-run per-project setup (change runtimes, ports, etc.)
matrix config

# Tear down all images
matrix destroy
```

## Per-Project Settings

The first time you run `matrix start` in a directory, it auto-detects your project and runs setup:

```
[matrix] First-time setup for this project

[matrix] Detected runtimes: node python
  Override detected runtimes? (available: node python php) [n]:
  Map ~/.ssh into container? [y/N]
  Pass Claude Code auth into container? [y/N]
  Pass Codex auth into container? [y/N]
  Ports to expose (comma-separated) [52431]:
  Add .matrix to .gitignore? [Y/n]

[matrix] Saved to .matrix/settings.json
```

Settings are saved to `.matrix/settings.json` in your project directory. Run `matrix config` to change them at any time. CLI flags (`-p`, `-n`) override saved settings.

## How It Works

Running `matrix start` in any project directory:

1. Reads per-project settings from `.matrix/settings.json` (or runs first-time setup)
2. Auto-detects language runtimes from project files
3. Builds a project-specific image by composing pre-built runtime layers (cached after first build)
4. Mounts your current directory into the container at `/host`
5. Forwards the host Docker socket so you can run Docker commands inside
6. Optionally mounts `~/.ssh` (read-only) for git operations
7. Optionally passes Claude Code and Codex credentials through
8. Exposes ports for dev servers
9. Names the container after your project — re-running reconnects to it

### AI auth passthrough

- **Claude Code:** credentials are read from the macOS Keychain (or `~/.claude/.credentials.json` on Linux) and injected as `CLAUDE_CODE_OAUTH_TOKEN`; `~/.claude` and `~/.claude.json` are mounted read-only.
- **Codex:** `~/.codex` (which holds `auth.json` and config) is mounted read-write so token refreshes inside the container persist. Run `codex login` on the host first.

## Project Structure

```
~/.matrix/
├── matrix                      # CLI entrypoint
├── install.sh                  # Curl installer
├── Dockerfile.base             # Base image (tools, editor, no runtimes)
├── Dockerfile.runtime-node     # Node 22 runtime image
├── Dockerfile.runtime-python   # Python 3 runtime image
├── Dockerfile.runtime-php      # PHP 8.5 + Composer runtime image
├── bin/
│   └── runtime                 # In-container runtime installer
├── shims/                      # Shim scripts for missing runtime commands
├── lib/
│   ├── utils.sh                # Colors, messaging, helpers
│   ├── config.sh               # Settings load/save/setup
│   ├── detect.sh               # Runtime auto-detection
│   ├── build.sh                # Image resolution and local builds
│   └── docker.sh               # Docker auth, run args
├── commands/
│   ├── enter.sh                # Enter/reconnect to container
│   ├── build.sh                # Rebuild the project image
│   ├── stop.sh                 # Stop a container
│   ├── list.sh                 # List active containers
│   ├── destroy.sh              # Remove all images
│   └── update.sh               # Pull latest and rebuild
├── config/
│   ├── zshrc                   # Zsh configuration
│   ├── p10k.zsh                # Powerlevel10k theme
│   ├── tmux.conf               # Tmux configuration
│   └── nvim/                   # Neovim configuration (Lazy.nvim)
└── .github/workflows/
    └── build-images.yml        # CI to build & push images to GHCR
```
