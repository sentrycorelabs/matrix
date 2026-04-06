#!/usr/bin/env bash

cmd_list() {
    msg "$BLUE" "Active Matrix containers:"
    docker ps --filter "name=${CONTAINER_PREFIX}-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}
