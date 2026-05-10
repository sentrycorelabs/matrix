#!/usr/bin/env bash

# ─── Image Registry ─────────────────────────────────────────────

MATRIX_REGISTRY="ghcr.io/sentrycorelabs/matrix"

# ─── Image Name Resolution ──────────────────────────────────────

get_image_name() {
    local runtimes_str="$1"

    if [[ -z "$runtimes_str" ]]; then
        echo "${MATRIX_REGISTRY}:base"
        return
    fi

    # Sort runtimes alphabetically and join with hyphen
    local sorted
    sorted=$(echo "$runtimes_str" | tr ' ' '\n' | sort | tr '\n' '-' | sed 's/-$//')
    echo "matrix-${sorted}"
}

# ─── Published Image Fallbacks ──────────────────────────────────

ensure_base_image() {
    local image_name="${MATRIX_REGISTRY}:base"

    if docker image inspect "$image_name" &>/dev/null; then
        return 0
    fi

    msg "$CYAN" "Pulling base image..."
    if docker pull "$image_name" >&2; then
        return 0
    fi

    msg "$YELLOW" "Base image pull failed; building locally from Dockerfile.base..."
    if ! docker build -t "$image_name" -f "$MATRIX_HOME/Dockerfile.base" "$MATRIX_HOME" >&2; then
        msg "$RED" "Failed to build base image locally."
        return 1
    fi
}

ensure_runtime_image() {
    local runtime="$1"
    local image_name="${MATRIX_REGISTRY}:runtime-${runtime}"
    local dockerfile="${MATRIX_HOME}/Dockerfile.runtime-${runtime}"

    if docker image inspect "$image_name" &>/dev/null; then
        return 0
    fi

    msg "$CYAN" "Pulling ${runtime} runtime..."
    if docker pull "$image_name" >&2; then
        return 0
    fi

    if [[ ! -f "$dockerfile" ]]; then
        msg "$RED" "No Dockerfile found for runtime: ${runtime}"
        return 1
    fi

    msg "$YELLOW" "${runtime} runtime pull failed; building locally..."
    if ! docker build -t "$image_name" -f "$dockerfile" "$MATRIX_HOME" >&2; then
        msg "$RED" "Failed to build ${runtime} runtime locally."
        return 1
    fi
}

# ─── Local Image Build ──────────────────────────────────────────

ensure_image() {
    local runtimes_str="$1"
    local image_name
    image_name=$(get_image_name "$runtimes_str")

    # No runtimes — use base image directly (pull if needed)
    if [[ -z "$runtimes_str" ]]; then
        ensure_base_image || return 1
        echo "$image_name"
        return
    fi

    # Check if local image already exists
    if docker image inspect "$image_name" &>/dev/null; then
        echo "$image_name"
        return
    fi

    # Ensure base and runtime layers are available. Published images are used
    # when accessible; otherwise the local Dockerfiles are the source of truth.
    ensure_base_image || return 1
    for rt in $runtimes_str; do
        ensure_runtime_image "$rt" || return 1
    done

    # Generate Dockerfile in memory
    msg "$CYAN" "Building project image (${image_name})..."
    local dockerfile="FROM ${MATRIX_REGISTRY}:base"

    for rt in $runtimes_str; do
        dockerfile="${dockerfile}
COPY --from=${MATRIX_REGISTRY}:runtime-${rt} / /"
    done

    # Build from stdin — no build context needed
    if ! echo "$dockerfile" | docker build -t "$image_name" -f - . >&2; then
        msg "$RED" "Failed to build project image."
        msg "$RED" "A runtime image may not be published yet. Run: matrix update"
        return 1
    fi

    echo "$image_name"
}
