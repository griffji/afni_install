#!/bin/bash

# Logging utilities
LOG_FILE="/tmp/afni_install.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    log_message "ERROR: $1"
    exit 1
}