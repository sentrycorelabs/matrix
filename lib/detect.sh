#!/usr/bin/env bash

# ─── Runtime Auto-Detection ──────────────────────────────────────

AVAILABLE_RUNTIMES=("node" "python" "php")

detect_runtimes() {
    local detected=()

    # Node
    if [[ -f "package.json" || -f "yarn.lock" || -f "pnpm-lock.yaml" || -f ".nvmrc" ]]; then
        detected+=("node")
    fi

    # Python
    if [[ -f "requirements.txt" || -f "pyproject.toml" || -f "setup.py" || -f "Pipfile" || -f ".python-version" ]]; then
        detected+=("python")
    fi

    # PHP
    if [[ -f "composer.json" || -f "artisan" ]]; then
        detected+=("php")
    fi

    echo "${detected[*]}"
}
