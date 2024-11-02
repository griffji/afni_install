#!/bin/bash

# Exit on error
set -e

INSTALL_DIR="/opt/nialbn_software/afni"
LOG_FILE="/tmp/afni_install.log"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Logging functions
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    log_message "ERROR: $1"
    exit 1
}

# Check functions
check_directory() {
    if [ -d "$INSTALL_DIR" ]; then
        if [ -f "$INSTALL_DIR/afni" ]; then
            log_message "AFNI is already installed in $INSTALL_DIR"
            return 0
        fi
    fi
    return 1
}

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

# Installation steps
install_system_packages() {
    local packages=(
        git tcsh python3 python3-devel gcc libXt-devel libXext-devel
        libX11-devel motif-devel gsl-devel netpbm-progs gnuplot
        xorg-x11-server-Xvfb R-devel cmake qt5-qtbase-devel file
        libpng-devel libjpeg-turbo-devel mesa-libGLU-devel
        mesa-libGL-devel mesa-dri-drivers python3-qt5 firefox
    )
    
    local packages_to_install=()
    
    # Check EPEL repository
    if ! check_package epel-release; then
        log_message "Installing EPEL repository..."
        sudo dnf install -y epel-release
    fi

    # Check which packages need to be installed
    for pkg in "${packages[@]}"; do
        if ! check_package "$pkg"; then
            packages_to_install+=("$pkg")
        fi
    done

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        log_message "Installing missing system packages: ${packages_to_install[*]}"
        sudo dnf install -y "${packages_to_install[@]}"
    else
        log_message "All required system packages are already installed"
    fi
}

install_python_packages() {
    local packages=(numpy scipy matplotlib pandas jupyter)
    local packages_to_install=()

    for pkg in "${packages[@]}"; do
        if ! check_python_package "$pkg"; then
            packages_to_install+=("$pkg")
        fi
    done

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        log_message "Installing missing Python packages: ${packages_to_install[*]}"
        sudo pip3 install "${packages_to_install[@]}"
    else
        log_message "All required Python packages are already installed"
    fi
}

download_setup_scripts() {
    log_message "Downloading AFNI setup scripts..."
    cd "$HOME"
    curl -O https://raw.githubusercontent.com/afni/afni/master/src/other_builds/OS_notes.linux_rocky_8_a_admin.txt
    curl -O https://raw.githubusercontent.com/afni/afni/master/src/other_builds/OS_notes.linux_rocky_8_b_user.tcsh
    curl -O https://raw.githubusercontent.com/afni/afni/master/src/other_builds/OS_notes.linux_rocky_8_c_nice.tcsh
}

run_setup_scripts() {
    log_message "Running AFNI setup scripts..."
    
    # Run admin setup
    log_message "Running admin setup..."
    sudo bash OS_notes.linux_rocky_8_a_admin.txt 2>&1 | tee o.rocky_8_a.txt
    
    # Run user setup
    log_message "Running user setup..."
    tcsh OS_notes.linux_rocky_8_b_user.tcsh 2>&1 | tee o.rocky_8_b.txt
    
    # Run nice setup
    log_message "Running nice setup..."
    tcsh OS_notes.linux_rocky_8_c_nice.tcsh 2>&1 | tee o.rocky_8_c.txt
}

setup_r_packages() {
    # Check if R packages are installed
    if ! Rscript -e "packageVersion('reshape2')" >/dev/null 2>&1 || \
       ! Rscript -e "packageVersion('ggplot2')" >/dev/null 2>&1; then
        log_message "Installing required R packages..."
        sudo R -e "install.packages(c('reshape2', 'ggplot2'), repos='http://cran.rstudio.com/')"
    else
        log_message "Required R packages are already installed"
    fi
}

install_afni() {
    if ! check_directory; then
        log_message "Creating AFNI installation directory..."
        sudo mkdir -p "$INSTALL_DIR"
        
        log_message "Downloading and installing AFNI..."
        cd "$INSTALL_DIR"
        curl -O https://afni.nimh.nih.gov/pub/dist/tgz/linux_openmp_64.tgz
        tar xvzf linux_openmp_64.tgz
        rm linux_openmp_64.tgz

        # Download sample data only if not already present
        if [ ! -d "$INSTALL_DIR/CD" ]; then
            log_message "Downloading bootcamp data..."
            curl -O https://afni.nimh.nih.gov/pub/dist/edu/data/CD.tgz
            tar xvzf CD.tgz
            rm CD.tgz
        fi

        # Set permissions for shared environment
        sudo chown -R $(whoami):$(whoami) "$INSTALL_DIR"
        sudo chmod -R 755 "$INSTALL_DIR"
    fi
}

setup_environment() {
    # Check if environment variables are already set
    if ! grep -q "AFNI_PLUGINPATH" ~/.bashrc; then
        log_message "Setting up environment variables..."
        echo 'export PATH=$PATH:/opt/nialbn_software/afni' >> ~/.bashrc
        echo 'export AFNI_PLUGINPATH=/opt/nialbn_software/afni' >> ~/.bashrc
    fi

    # Setup AFNI configuration if not already present
    if [ ! -f ~/.afnirc ]; then
        log_message "Setting up AFNI configuration..."
        echo "# AFNI configuration" > ~/.afnirc
        echo "AFNI_SPLASH_SCREEN = NO" >> ~/.afnirc
        echo "AFNI_PACKAGEDATA = YES" >> ~/.afnirc
        echo "AFNI_IMSAVE_WARNINGS = NO" >> ~/.afnirc
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
        afni -ver
    else
        log_error "GUI applications not found"
    fi
}

main() {
    log_message "Starting AFNI installation process..."
    
    install_system_packages
    install_python_packages
    setup_r_packages
    download_setup_scripts
    run_setup_scripts
    install_afni
    setup_environment
    verify_installation
    
    log_message "AFNI installation complete. Please restart your terminal or run 'source ~/.bashrc' to use AFNI."
}

# Run main function
main