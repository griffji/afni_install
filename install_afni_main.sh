#!/bin/bash

# Main installation script for AFNI
set -e

INSTALL_DIR="/opt/nialbn_software/afni"
LOG_FILE="/tmp/afni_install.log"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source helper functions
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/package_utils.sh"
source "${SCRIPT_DIR}/lib/install_steps.sh"

main() {
    log_message "Starting AFNI installation process..."
    
    # Download AFNI setup scripts
    download_setup_scripts
    
    # Run official AFNI setup steps
    run_admin_setup
    run_user_setup
    run_nice_setup
    
    # Install AFNI in shared directory
    install_afni_shared
    
    # Verify installation
    verify_installation
    
    log_message "AFNI installation complete. Please restart your terminal or run 'source ~/.bashrc'"
}

main