#!/bin/bash

download_setup_scripts() {
    log_message "Downloading AFNI setup scripts..."
    cd "$HOME"
    curl -O https://raw.githubusercontent.com/afni/afni/master/src/other_builds/OS_notes.linux_rocky_8_a_admin.txt
    curl -O https://raw.githubusercontent.com/afni/afni/master/src/other_builds/OS_notes.linux_rocky_8_b_user.tcsh
    curl -O https://raw.githubusercontent.com/afni/afni/master/src/other_builds/OS_notes.linux_rocky_8_c_nice.tcsh
}

run_admin_setup() {
    log_message "Running AFNI admin setup..."
    sudo bash OS_notes.linux_rocky_8_a_admin.txt 2>&1 | tee o.rocky_8_a.txt
}

run_user_setup() {
    log_message "Running AFNI user setup..."
    tcsh OS_notes.linux_rocky_8_b_user.tcsh 2>&1 | tee o.rocky_8_b.txt
}

run_nice_setup() {
    log_message "Running AFNI nice setup..."
    tcsh OS_notes.linux_rocky_8_c_nice.tcsh 2>&1 | tee o.rocky_8_c.txt
}

install_afni_shared() {
    if ! check_directory; then
        log_message "Installing AFNI in shared directory..."
        sudo mkdir -p "$INSTALL_DIR"
        
        cd "$INSTALL_DIR"
        curl -O https://afni.nimh.nih.gov/pub/dist/tgz/linux_openmp_64.tgz
        tar xvzf linux_openmp_64.tgz
        rm linux_openmp_64.tgz

        if [ ! -d "$INSTALL_DIR/CD" ]; then
            log_message "Downloading bootcamp data..."
            curl -O https://afni.nimh.nih.gov/pub/dist/edu/data/CD.tgz
            tar xvzf CD.tgz
            rm CD.tgz
        fi

        sudo chown -R $(whoami):$(whoami) "$INSTALL_DIR"
        sudo chmod -R 755 "$INSTALL_DIR"
    fi
}

verify_installation() {
    log_message "Running AFNI system check..."
    source ~/.bashrc
    
    if ! command -v afni >/dev/null 2>&1; then
        log_error "AFNI installation verification failed"
    fi
    
    # Run comprehensive system check
    afni_system_check.py -check_all
    
    # Test GUI applications
    log_message "Testing AFNI and SUMA GUIs..."
    if command -v afni >/dev/null 2>&1 && command -v suma >/dev/null 2>&1; then
        log_message "GUI applications available"
    else
        log_error "GUI applications not found"
    fi
}