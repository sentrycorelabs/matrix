# Matrix

A portable, containerized development environment. One command drops you into a fully configured shell with your preferred tools, languages, and editor — on any machine with Docker.

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
- Claude Code (with automatic OAuth passthrough from macOS Keychain)

**Docker**
- Docker CLI + Compose plugin (talks to the host daemon via socket mount)

## Quick Start

```bash
# Build the image
./matrix build

# Enter the Matrix in your current project directory
./matrix
```

Your current working directory is mounted at `/app` inside the container.

## Usage

```
matrix [command] [options]

Commands:
  (none)       Enter the Matrix in the current directory
  build        Build/rebuild the Matrix image
  stop [name]  Stop a running container (default: current dir)
  list         List running Matrix containers
  destroy      Remove the Matrix image
  help         Show usage info

Options:
  -p PORT      Expose a port (default: 5173)
  -n NAME      Custom container name
```

### Examples

```bash
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

# Tear down the image entirely
matrix destroy
```

## Project Structure

```
Matrix/
├── Dockerfile          # Image definition
├── matrix              # CLI entrypoint
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

## How It Works

Running `./matrix` in any project directory:

1. Mounts your current directory into the container at `/app`
2. Forwards the host Docker socket so you can run Docker commands inside the container
3. Passes your Claude Code credentials through automatically (macOS Keychain)
4. Exposes a port for dev servers (default `5173`)
5. Names the container after your project directory — re-running reconnects to it instead of creating a new one

## Requirements

- Docker
- macOS (for automatic Claude Code auth passthrough; the container itself runs on any Docker host)
