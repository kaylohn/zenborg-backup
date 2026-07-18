# ZenBORG

ZenBORG is a streamlined backup utility for Linux environments that combines the power of [BorgBackup](https://www.borgbackup.org/) with a responsive [Zenity](https://help.gnome.org/users/zenity/stable/) GUI. It provides real-time progress monitoring, detailed backup statistics, and a clean interface for managing data archives.

## Features

*   **Deduplicated & Compressed**: Leverages BorgBackup to minimize storage usage.
*   **Visual Progress**: Features a pulsating progress bar that displays the current file being processed.
*   **Detailed Reporting**: Provides a clean summary table of statistics upon completion.
*   **Clipboard Ready**: Includes a "Copy Full Log" function to easily grab detailed file logs for troubleshooting.
*   **Configuration-Driven**: Designed to be modular with no hardcoded paths or credentials in the core logic.

## Prerequisites

Ensure the following dependencies are installed on your Debian-based system:

*   **BorgBackup**: `sudo apt install borgbackup`
*   **Zenity**: Usually pre-installed on MATE/GNOME.
*   **Clipboard Tool**: `xclip` (for X11) or `wl-clipboard` (for Wayland).

## Configuration

To avoid hardcoding, ZenBORG looks for a configuration file at `~/.config/zenborg/config`.

1. Create the directory: `mkdir -p ~/.config/zenborg`
2. Create a file named `config` in that directory:
   ```bash
   # ~/.config/zenborg/config
   BACKUP_DEST="/path/to/your/repo"
   SOURCE_FOLDERS=("/home/user/folder1" "/home/user/folder2")
