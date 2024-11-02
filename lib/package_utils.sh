#!/bin/bash

check_package() {
    if rpm -q "$1" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

check_python_package() {
    if pip3 list | grep -q "^$1[[:space:]]"; then
        return 0
    fi
    return 1
}

check_directory() {
    if [ -d "$INSTALL_DIR" ]; then
        if [ -f "$INSTALL_DIR/afni" ]; then
            log_message "AFNI is already installed in $INSTALL_DIR"
            return 0
        fi
    fi
    return 1
}