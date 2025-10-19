# Helium Browser Installer

A simple installer for [Helium Browser](https://github.com/imputnet/helium-linux)

## For first time installation

```bash
curl -fsSL https://raw.githubusercontent.com/ni3rav/helium-installer/main/install.sh | bash
```

After running the installer, you'll have a `helium` command:

```bash
helium                    # Launch the browser
helium --version          # Display installed version number
helium --update           # Update to a stable version (for now it is same as latest)
helium --update latest    # Update to the latest version
helium --uninstall        # Uninstall Helium
helium --help             # Shows this help
```

## What It Does

1. Downloads the latest Helium AppImage
2. Creates a launcher script at `~/.local/bin/helium`
3. Adds a desktop entry
4. Downloads the app icon
5. Keeps track of versions

## Uninstallation

Changed your mind? No hard feelings:

```bash
helium --uninstall
```

Or:

```bash
curl -fsSL https://raw.githubusercontent.com/ni3rav/helium-installer/main/uninstall.sh | bash
```

## 📋 Requirements

- A Linux system
- `curl` or `wget` (you probably have one)
- `unzip`

## Why This Exists

Because clicking through GitHub releases, downloading AppImages, making them executable, moving them to the right folder, and creating desktop entries is:

1. Boring
2. Error-prone
3. Something a script should do

## Issues?

The scripts are misbehaving? Open an issue and let's get it fixed!
