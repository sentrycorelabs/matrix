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

# ─── Local Image Build ──────────────────────────────────────────

ensure_image() {
    local runtimes_str="$1"
    local image_name
    image_name=$(get_image_name "$runtimes_str")

    # No runtimes — use base image directly (pull if needed)
    if [[ -z "$runtimes_str" ]]; then
        if ! docker image inspect "$image_name" &>/dev/null; then
            msg "$CYAN" "Pulling base image..."
            docker pull "$image_name"
        fi
        echo "$image_name"
        return
    fi

    # Check if local image already exists
    if docker image inspect "$image_name" &>/dev/null; then
        echo "$image_name"
        return
    fi

    # Generate Dockerfile in memory
    msg "$CYAN" "Building project image (${image_name})..."
    local dockerfile="FROM ${MATRIX_REGISTRY}:base"

    for rt in $runtimes_str; do
        dockerfile="${dockerfile}
COPY --from=${MATRIX_REGISTRY}:runtime-${rt} / /"
    done

    # Build from stdin — no build context needed
    echo "$dockerfile" | docker build -t "$image_name" -f - . > /dev/null

    echo "$image_name"
}
