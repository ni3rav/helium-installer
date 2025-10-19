#!/bin/bash

# Helium Browser Uninstaller

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

APP_NAME="Helium"
APP_COMMAND="helium"
APP_IMAGE_NAME="helium.AppImage"
INSTALL_DIR="$HOME/.local/bin"
DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"
CONFIG_DIR="$HOME/.config/helium"
CACHE_DIR="$HOME/.cache/helium"

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -p "$prompt" -r
    if [[ -z "$REPLY" ]]; then
        REPLY="$default"
    fi
    
    [[ "$REPLY" =~ ^[Yy]$ ]]
}

exists() {
    [[ -e "$1" ]]
}

remove_file() {
    local file="$1"
    if exists "$file"; then
        print_status "Removing $file..."
        rm -f "$file"
        print_success "Removed $file"
    else
        print_warning "$file does not exist, skipping..."
    fi
}

remove_directory() {
    local dir="$1"
    if exists "$dir"; then
        print_status "Removing directory $dir..."
        rm -rf "$dir"
        print_success "Removed directory $dir"
    else
        print_warning "$dir does not exist, skipping..."
    fi
}

remove_main_script() {
    local script_path="$INSTALL_DIR/$APP_COMMAND"
    remove_file "$script_path"
}

remove_appimage() {
    local appimage_path="$INSTALL_DIR/$APP_IMAGE_NAME"
    remove_file "$appimage_path"
    
    local version_file="$INSTALL_DIR/.helium_version"
    if exists "$version_file"; then
        remove_file "$version_file"
    fi
}

remove_desktop_entry() {
    local desktop_entry="$DESKTOP_ENTRY_DIR/helium.desktop"
    remove_file "$desktop_entry"
}

remove_icon() {
    local icon_path="$ICON_DIR/helium.png"
    remove_file "$icon_path"
}

remove_config() {
    if exists "$CONFIG_DIR"; then
        print_warning "Configuration directory found: $CONFIG_DIR"
        if confirm "Do you want to remove $APP_NAME configuration files?"; then
            remove_directory "$CONFIG_DIR"
        else
            print_status "Keeping configuration files"
        fi
    fi
}

remove_cache() {
    if exists "$CACHE_DIR"; then
        print_warning "Cache directory found: $CACHE_DIR"
        if confirm "Do you want to remove $APP_NAME cache files?"; then
            remove_directory "$CACHE_DIR"
        else
            print_status "Keeping cache files"
        fi
    fi
}

check_installation() {
    local installed=false
    
    if exists "$INSTALL_DIR/$APP_COMMAND" || exists "$INSTALL_DIR/$APP_IMAGE_NAME"; then
        installed=true
    fi
    
    if [[ "$installed" == false ]]; then
        print_warning "$APP_NAME does not appear to be installed"
        if ! confirm "Do you want to continue with the uninstall process?"; then
            print_status "Uninstall cancelled"
            exit 0
        fi
    fi
}

show_summary() {
    echo
    print_success "Uninstall complete!"
    echo
    print_status "The following items have been removed:"
    echo "  - $APP_NAME command script"
    echo "  - $APP_NAME AppImage"
    echo "  - Desktop entry"
    echo "  - Application icon"
    
    if exists "$CONFIG_DIR" || exists "$CACHE_DIR"; then
        echo
        print_status "The following items were kept:"
        if exists "$CONFIG_DIR"; then
            echo "  - Configuration files: $CONFIG_DIR"
        fi
        if exists "$CACHE_DIR"; then
            echo "  - Cache files: $CACHE_DIR"
        fi
        echo
        print_status "You can manually remove these directories if needed:"
        if exists "$CONFIG_DIR"; then
            echo "  rm -rf $CONFIG_DIR"
        fi
        if exists "$CACHE_DIR"; then
            echo "  rm -rf $CACHE_DIR"
        fi
    fi
}

show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --version      Show uninstaller version"
    echo "  --force        Skip confirmation prompts"
    echo
    echo "This script will remove $APP_NAME and all associated files."
    echo "You will be prompted before removing configuration and cache files."
}

main() {
    local force=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                echo "$APP_NAME Uninstaller v1.0.0"
                exit 0
                ;;
            --force)
                force=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_status "Starting $APP_NAME uninstall process..."
    echo
    
    check_installation
    
    if [[ "$force" != true ]]; then
        if ! confirm "Are you sure you want to uninstall $APP_NAME?"; then
            print_status "Uninstall cancelled"
            exit 0
        fi
    fi
    
    echo
    print_status "Removing $APP_NAME components..."
    
    remove_main_script
    remove_appimage
    remove_desktop_entry
    remove_icon
    
    if [[ "$force" != true ]]; then
        echo
        remove_config
        remove_cache
    else
        remove_directory "$CONFIG_DIR"
        remove_directory "$CACHE_DIR"
    fi
    
    show_summary
}

main "$@"
