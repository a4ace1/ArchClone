#!/usr/bin/env bash

set -Eeuo pipefail

source lib/logging.sh

init_logger "./logs"

info "Starting ArchForge test"
success "Logging initialized successfully"
warn "This is a warning"
debug "Debug message"
error "This is a test error"

echo
echo "Test completed."
