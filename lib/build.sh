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

    # Ensure base and runtime layers are available. Published images are used
    # when accessible; otherwise the local Dockerfiles are the source of truth.
    ensure_base_image || return 1
    for rt in $runtimes_str; do
        ensure_runtime_image "$rt" || return 1
    done

    # Fingerprint of the layer images this composition is built from. Stored
    # as a label so a stale composed image rebuilds automatically when the
    # base or a runtime image changes (rmi can fail silently while a
    # container is running, so absence of the image can't be relied on).
    # COMPOSE_VERSION: bump when the generated Dockerfile below changes,
    # so existing composed images rebuild even if layer IDs are unchanged.
    local COMPOSE_VERSION=2
    local fingerprint
    fingerprint="v${COMPOSE_VERSION}:$(docker image inspect -f '{{.Id}}' "${MATRIX_REGISTRY}:base")"
    for rt in $runtimes_str; do
        fingerprint="${fingerprint},$(docker image inspect -f '{{.Id}}' "${MATRIX_REGISTRY}:runtime-${rt}")"
    done

    # Reuse the existing composed image only if its layers are current
    if docker image inspect "$image_name" &>/dev/null; then
        local existing_fp
        existing_fp=$(docker image inspect -f '{{index .Config.Labels "matrix.layers"}}' "$image_name" 2>/dev/null)
        if [[ "$existing_fp" == "$fingerprint" ]]; then
            echo "$image_name"
            return
        fi
        msg "$YELLOW" "Base or runtime images changed; rebuilding ${image_name}..."
    fi

    # Generate Dockerfile in memory
    msg "$CYAN" "Building project image (${image_name})..."
    local dockerfile="FROM ${MATRIX_REGISTRY}:base"

    for rt in $runtimes_str; do
        dockerfile="${dockerfile}
COPY --from=${MATRIX_REGISTRY}:runtime-${rt} / /"
    done

    # Runtime layers clobber /etc/passwd — restore zsh as root's shell
    dockerfile="${dockerfile}
RUN chsh -s /usr/bin/zsh root"

    # Build from stdin — no build context needed
    if ! echo "$dockerfile" | docker build -t "$image_name" --label "matrix.layers=${fingerprint}" -f - . >&2; then
        msg "$RED" "Failed to build project image."
        msg "$RED" "A runtime image may not be published yet. Run: matrix update"
        return 1
    fi

    echo "$image_name"
}
