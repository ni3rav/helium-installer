#!/bin/bash

# Helium Browser Launcher Script

set -e

# Configuration
APP_NAME="Helium"
APP_COMMAND="helium"
APP_IMAGE_NAME="helium.AppImage"
GITHUB_REPO="imputnet/helium-linux"
APP_ICON_URL=""   # TODO: Replace with actual Helium icon URL if available
INSTALL_DIR="$HOME/.local/bin"
DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"
CONFIG_DIR="$HOME/.config/helium"
CACHE_DIR="$HOME/.cache/helium"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

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

get_latest_version() {
    print_status "Fetching latest version from GitHub..."
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

get_stable_version() {
    # For now, stable is the same as latest
    get_latest_version
}

get_download_url() {
    local version="$1"
    # URL format: https://github.com/imputnet/helium-linux/releases/download/VERSION/helium-VERSION-x86_64.AppImage
    echo "https://github.com/$GITHUB_REPO/releases/download/$version/helium-$version-x86_64.AppImage"
}

get_current_version() {
    local appimage_path="$INSTALL_DIR/$APP_IMAGE_NAME"
    
    if [[ -f "$appimage_path" ]]; then
        # Try to extract version from filename in the backup or use a version file
        if [[ -f "$INSTALL_DIR/.helium_version" ]]; then
            cat "$INSTALL_DIR/.helium_version"
        else
            echo "unknown"
        fi
    else
        echo "not_installed"
    fi
}

save_version() {
    local version="$1"
    echo "$version" > "$INSTALL_DIR/.helium_version"
}

download_file() {
    local url="$1"
    local output="$2"
    
    if command_exists curl; then
        curl -L "$url" -o "$output"
    elif command_exists wget; then
        wget -O "$output" "$url"
    else
        print_error "Neither curl nor wget is available"
        exit 1
    fi
}

create_directories() {
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$DESKTOP_ENTRY_DIR"
    mkdir -p "$ICON_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$CACHE_DIR"
}

update_helium() {
    local version_type="$1"
    local version
    
    if [[ "$version_type" == "latest" ]]; then
        version=$(get_latest_version)
    else
        version=$(get_stable_version)
    fi
    
    print_status "Updating $APP_NAME to version $version..."
    
    local download_url=$(get_download_url "$version")
    print_status "Download URL: $download_url"
    
    local appimage_path="$INSTALL_DIR/$APP_IMAGE_NAME"
    if [[ -f "$appimage_path" ]]; then
        print_status "Creating backup of current version..."
        cp "$appimage_path" "$appimage_path.backup"
    fi
    
    print_status "Downloading $APP_NAME $version..."
    download_file "$download_url" "$appimage_path.new"
    
    if [[ -f "$appimage_path.new" ]]; then
        chmod +x "$appimage_path.new"
        
        if [[ -f "$appimage_path" ]]; then
            rm "$appimage_path"
        fi
        mv "$appimage_path.new" "$appimage_path"
        
        # Save the version
        save_version "$version"
        
        update_desktop_entry
        
        print_success "$APP_NAME updated to version $version"
        
        if [[ -f "$appimage_path.backup" ]]; then
            rm "$appimage_path.backup"
        fi
    else
        print_error "Failed to download $APP_NAME"
        if [[ -f "$appimage_path.backup" ]]; then
            mv "$appimage_path.backup" "$appimage_path"
            print_status "Restored previous version"
        fi
        exit 1
    fi
}

# Function to update desktop entry
update_desktop_entry() {
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
}

# Function to show version
show_version() {
    local current_version=$(get_current_version)
    
    if [[ "$current_version" == "not_installed" ]]; then
        print_error "$APP_NAME is not installed"
        exit 1
    else
        echo "$APP_NAME version: $current_version"
    fi
}

# Function to show help
show_help() {
    echo "Usage: $APP_COMMAND [options] [arguments...]"
    echo
    echo "Options:"
    echo "  --update [version]    Update $APP_NAME (stable|latest)"
    echo "  --version, -v         Show current version"
    echo "  --help, -h            Show this help message"
    echo
    echo "Examples:"
    echo "  $APP_COMMAND                    # Launch $APP_NAME"
    echo "  $APP_COMMAND --update           # Update to stable version"
    echo "  $APP_COMMAND --update latest    # Update to latest version"
    echo "  $APP_COMMAND --version          # Show version"
    echo "  $APP_COMMAND file.txt           # Open file in $APP_NAME"
    echo "  $APP_COMMAND --new-window       # Open new window"
}

# Function to launch Helium
launch_helium() {
    local appimage_path="$INSTALL_DIR/$APP_IMAGE_NAME"
    
    if [[ ! -f "$appimage_path" ]]; then
        print_error "$APP_NAME is not installed"
        print_status "Run the installer first: curl -fsSL https://raw.githubusercontent.com/yourusername/helium-installer/main/install.sh | bash"
        exit 1
    fi
    
    # Create directories if they don't exist
    create_directories
    
    # Launch the application with all passed arguments
    exec "$appimage_path" "$@"
}

# Main function
main() {
    # Handle command line arguments
    case "${1:-}" in
        --update)
            local version="${2:-stable}"
            if [[ "$version" == "latest" ]]; then
                update_helium "latest"
            elif [[ "$version" == "stable" ]]; then
                update_helium "stable"
            else
                print_error "Invalid version: $version"
                print_error "Use 'stable' or 'latest'"
                exit 1
            fi
            ;;
        --version|-v)
            show_version
            ;;
        --help|-h)
            show_help
            ;;
        *)
            launch_helium "$@"
            ;;
    esac
}

# Run main function
main "$@"
