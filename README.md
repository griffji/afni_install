# AFNI Installation for HPC

This script set provides an idempotent installation of AFNI for Rocky Linux 8 in an HPC environment.

## Usage

1. Make the main script executable:
   ```bash
   chmod +x install_afni_main.sh
   ```

2. Run the installation:
   ```bash
   ./install_afni_main.sh
   ```

## Features

- Modular design with separate components
- Idempotent installation
- HPC-friendly with shared directory support
- Comprehensive logging
- Official AFNI setup integration
- System verification and GUI testing

## Directory Structure

- `install_afni_main.sh`: Main installation script
- `lib/`
  - `logging.sh`: Logging utilities
  - `package_utils.sh`: Package management functions
  - `install_steps.sh`: Installation steps implementation