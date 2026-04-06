# Matrix

A portable, containerized development environment. One command drops you into a fully configured shell with your preferred tools, languages, and editor — on any machine with Docker.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/sentrycorelabs/matrix/main/install.sh | sh
```

This clones the repo to `~/.matrix/`, symlinks the CLI to `/usr/local/bin/matrix`, and builds the Docker image.

**Requirements:** Docker and Git.

## What's Inside

**Languages & Runtimes**
- Node.js 20
- Python 3 (with pip & venv)
- PHP 8.5 (with Composer)

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

**Docker**
- Docker CLI + Compose plugin (talks to the host daemon via socket mount)

## Usage

```
matrix [command] [options]

Commands:
  (none)       Enter the Matrix in the current directory
  build        Build/rebuild the Matrix image
  stop [name]  Stop a running container (default: current dir)
  list         List running Matrix containers
  destroy      Remove the Matrix image
  config       Re-run setup for the current directory
  update       Pull latest and rebuild the image
  help         Show usage info

Options:
  -p PORT      Expose a port (default: 5173)
  -n NAME      Custom container name
```

### Examples

```bash
# Enter the Matrix in your current project directory
matrix

# Enter with a custom port
matrix -p 3000

# Enter with a custom container name
matrix -n api-project

# Reconnect to a running container (automatic — just run matrix again)
matrix

# List all active containers
matrix list

# Stop a specific container
matrix stop api-project

# Update Matrix to the latest version
matrix update

# Re-run per-project setup
matrix config

# Tear down the image entirely
matrix destroy
```

## Per-Project Settings

The first time you run `matrix` in a directory, it runs an interactive setup:

```
[matrix] First-time setup for this project

  Map ~/.ssh into container? [Y/n]
  Pass Claude Code auth into container? [Y/n]
  Default port [5173]:
  Add .matrix to .gitignore? [Y/n]

[matrix] Saved to .matrix/settings.json
```

Settings are saved to `.matrix/settings.json` in your project directory. Run `matrix config` to change them at any time. CLI flags (`-p`, `-n`) override saved settings.

## How It Works

Running `matrix` in any project directory:

1. Reads per-project settings from `.matrix/settings.json` (or runs first-time setup)
2. Mounts your current directory into the container at `/app`
3. Forwards the host Docker socket so you can run Docker commands inside the container
4. Optionally mounts `~/.ssh` (read-only) for git operations
5. Optionally passes Claude Code credentials through (macOS Keychain)
6. Exposes a port for dev servers (default `5173`)
7. Names the container after your project directory — re-running reconnects to it instead of creating a new one

## Project Structure

```
~/.matrix/
├── Dockerfile          # Image definition
├── matrix              # CLI entrypoint
├── install.sh          # Curl installer
├── config/
│   ├── zshrc           # Zsh configuration
│   ├── p10k.zsh        # Powerlevel10k theme
│   ├── tmux.conf       # Tmux configuration
│   └── nvim/           # Neovim configuration (Lazy.nvim)
│       ├── init.lua
│       ├── lazy-lock.json
│       └── lua/
│           ├── core/   # keymaps, options, lazy bootstrap
│           └── plugins/# plugin specs
└── .dockerignore
```
