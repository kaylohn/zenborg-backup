# ZenBORG

A peaceful, local, deduplicated, and highly secure backup wrapper built on Borg and Zenity.

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

============================================================
             ZenBORG — BACKUP REFERENCE MANUAL
============================================================

1. GETTING STARTED
   - Configuration: Define where your "Vault" lives (e.g., an external 
     drive). Add the local folders you wish to protect.
   - Initializing: The first time you pick a destination, 
     ZenBORG will initialize a new, encrypted Vault. 

2. THE "VAULT" (REPOSITORY)
   - Your backup repository is a secure, encrypted container.
   - Passphrase: You will set this during initialization. 
     Do not lose it—it is the only way to recover your data.

3. MOUNTING & RESTORING
   - Mounting: Uses FUSE to expose the Vault as a regular folder 
     at ~/Borg_Mount. 
   - Restoring: Once mounted, simply drag-and-drop or copy files 
     from the mount point back to your system.
   - Safety: Always click "Unmount" inside the app before 
     unplugging your external drive to prevent corruption.

4. AUTOMATED MAINTENANCE
   - The app detects and handles installation of missing 
     dependencies (Borg, Zenity) based on your system's 
     package manager.
   - Integrity Checks: Run this if the system crashes during 
     a backup to release "stale locks" and ensure archive health.

5. SECURITY NOTE
   - Configuration is stored in ~/.config/zenborg-backup-utility.
   - Your passphrase is NEVER stored in cleartext by this application.
============================================================