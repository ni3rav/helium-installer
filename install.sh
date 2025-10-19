#!/bin/bash

# Helium Browser Linux Installer

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_NAME="Helium"
APP_COMMAND="helium"
APP_IMAGE_NAME="helium.AppImage"
GITHUB_REPO="imputnet/helium-linux"
APP_ICON_URL="https://raw.githubusercontent.com/imputnet/helium/refs/heads/main/resources/branding/app_icon/raw.png"
INSTALL_DIR="$HOME/.local/bin"
DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"
SCRIPT_URL="https://raw.githubusercontent.com/ni3rav/helium-installer/main/helium.sh"

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

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        exit 1
    fi
}

check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command_exists curl && ! command_exists wget; then
        print_error "curl or wget is required but not installed"
        exit 1
    fi
    
    if ! command_exists unzip; then
        print_error "unzip is required but not installed"
        exit 1
    fi
    
    print_success "All dependencies are installed"
}

create_directories() {
    print_status "Creating directories..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$DESKTOP_ENTRY_DIR"
    mkdir -p "$ICON_DIR"
    print_success "Directories created"
}

download_file() {
    local url="$1"
    local output="$2"
    
    if command_exists curl; then
        curl -L "$url" -o "$output"
    elif command_exists wget; then
        wget -O "$output" "$url"
    fi
}

get_latest_version() {
    print_status "Fetching latest version from GitHub..." >&2
    local version
    
    if command_exists curl; then
        version=$(curl -fsSL "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    elif command_exists wget; then
        version=$(wget -qO- "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        print_error "Neither curl nor wget is available"
        exit 1
    fi
    
    if [[ -z "$version" ]]; then
        print_error "Failed to fetch latest version"
        exit 1
    fi
    
    echo "$version"
}

get_download_url() {
    local version="$1"
    # URL format: https://github.com/imputnet/helium-linux/releases/download/VERSION/helium-VERSION-x86_64.AppImage
    echo "https://github.com/$GITHUB_REPO/releases/download/$version/helium-$version-x86_64.AppImage"
}

save_version() {
    local version="$1"
    echo "$version" > "$INSTALL_DIR/.helium_version"
}

install_main_script() {
    print_status "Downloading $APP_NAME script..."
    
    if command_exists curl; then
        curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/$APP_COMMAND"
    elif command_exists wget; then
        wget -qO- "$SCRIPT_URL" > "$INSTALL_DIR/$APP_COMMAND"
    fi
    
    chmod +x "$INSTALL_DIR/$APP_COMMAND"
    print_success "$APP_NAME script installed"
}

check_path() {
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        print_warning "$HOME/.local/bin is not in your PATH"
        print_warning "You can add it by running:"
        print_warning "export PATH=\"\$HOME/.local/bin:\$PATH\""
        print_warning "Or add it to your shell profile (e.g., .bashrc, .zshrc, etc.)"
    fi
}

install_helium() {
    print_status "Installing $APP_NAME..."
    
    # Get the latest version
    local version=$(get_latest_version)
    print_success "Latest version: $version"
    
    # Get the download URL
    local download_url=$(get_download_url "$version")
    print_status "Download URL: $download_url"
    
    print_status "Downloading $APP_NAME AppImage..."
    download_file "$download_url" "$INSTALL_DIR/$APP_IMAGE_NAME"
    chmod +x "$INSTALL_DIR/$APP_IMAGE_NAME"
    
    # Save the version
    save_version "$version"
    
    if [[ -n "$APP_ICON_URL" ]]; then
        print_status "Downloading $APP_NAME icon..."
        download_file "$APP_ICON_URL" "$ICON_DIR/helium.png"
    fi
    
    print_success "$APP_NAME version $version installed successfully"
}

create_desktop_entry() {
    print_status "Creating desktop entry..."
    
    local icon_path=""
    if [[ -n "$APP_ICON_URL" ]]; then
        icon_path="$ICON_DIR/helium.png"
    fi
    
    cat > "$DESKTOP_ENTRY_DIR/helium.desktop" << EOF
[Desktop Entry]
Name=$APP_NAME
Comment=AI-powered web browser
Exec=$INSTALL_DIR/$APP_IMAGE_NAME
Icon=$icon_path
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOF
    
    chmod +x "$DESKTOP_ENTRY_DIR/helium.desktop"
    print_success "Desktop entry created"
}

show_usage() {
    print_success "Installation complete!"
    echo
    print_status "You can now use the following commands:"
    echo "  $APP_COMMAND                    - Launch $APP_NAME"
    echo "  $APP_COMMAND --update          - Update $APP_NAME to stable version"
    echo "  $APP_COMMAND --update latest   - Update $APP_NAME to latest version"
    echo "  $APP_COMMAND --version         - Show $APP_NAME version"
    echo
    check_path
}

main() {
    print_status "Starting $APP_NAME installation..."
    
    check_root
    check_dependencies
    create_directories
    install_main_script
    install_helium
    create_desktop_entry
    show_usage
}

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --version      Show installer version"
    echo
    echo "This script will install $APP_NAME and provide a '$APP_COMMAND' command."
    exit 0
elif [[ "$1" == "--version" || "$1" == "-v" ]]; then
    echo "$APP_NAME Installer v1.0.0"
    exit 0
fi

main
