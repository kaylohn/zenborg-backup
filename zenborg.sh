#!/bin/bash

# ==========================================
# UNIVERSAL ZENITY GUARD (CLI-to-GUI Bootstrap)
# ==========================================
ensure_zenity_installed() {
    if command -v zenity >/dev/null 2>&1; then
        return 0
    fi

    clear
    echo "============================================================"
    echo "            ZenBORG BACKUP UTILITY — INITIALIZER            "
    echo "============================================================"
    echo ""
    echo "⚠️  Dependency Missing: 'zenity' (Graphical Dialog Engine) is required."
    echo "   To run this application, we need to install it on your system."
    echo ""

    local install_cmd=""
    local pkg_manager=""

    if command -v apt-get >/dev/null 2>&1; then
        pkg_manager="APT (Debian/Ubuntu)"
        install_cmd="apt-get update -y && apt-get install -y zenity"
    elif command -v pacman >/dev/null 2>&1; then
        pkg_manager="Pacman (Arch Linux)"
        install_cmd="pacman -Sy --noconfirm zenity"
    elif command -v dnf >/dev/null 2>&1; then
        pkg_manager="DNF (Fedora/RHEL)"
        install_cmd="dnf install -y zenity"
    elif command -v zypper >/dev/null 2>&1; then
        pkg_manager="Zypper (openSUSE)"
        install_cmd="zypper --non-interactive install zenity"
    elif command -v apk >/dev/null 2>&1; then
        pkg_manager="APK (Alpine)"
        install_cmd="apk add --no-cache zenity"
    elif command -v emerge >/dev/null 2>&1; then
        pkg_manager="Portage (Gentoo)"
        install_cmd="emerge --ask=n gnome-extra/zenity"
    elif command -v eopkg >/dev/null 2>&1; then
        pkg_manager="Eopkg (Solus)"
        install_cmd="eopkg install -y zenity"
    elif command -v xbps-install >/dev/null 2>&1; then
        pkg_manager="XBPS (Void)"
        install_cmd="xbps-install -Sy zenity"
    fi

    if [ -n "$install_cmd" ]; then
        echo "Detected Package Manager: $pkg_manager"
        echo "------------------------------------------------------------"
        read -p "Would you like to install Zenity automatically now? (y/N): " -r response
        echo ""

        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo "Requesting administrative privileges to install..."
            if command -v pkexec >/dev/null 2>&1; then
                pkexec sh -c "$install_cmd"
            else
                sudo sh -c "$install_cmd"
            fi

            if command -v zenity >/dev/null 2>&1; then
                echo "✅ Success! Zenity has been installed successfully."
                echo "🚀 Launching ZenBORG..."
                sleep 1.5
                exec "$0" "$@"
            else
                echo "❌ Error: Installation completed but 'zenity' is still missing."
                echo "Please install it manually using: $install_cmd"
                exit 1
            fi
        else
            echo "🚫 Aborted: Zenity is required to run this application. Exiting."
            exit 1
        fi
    else
        echo "❌ Your package manager could not be auto-detected."
        echo "   Please install 'zenity' manually using your system's package manager."
        exit 1
    fi
}

# 1. Boot up the guard immediately to ensure graphical capability
ensure_zenity_installed

# ==========================================
# CONSTANTS & CONFIGURATION PERSISTENCE
# ==========================================
CONFIG_DIR="$HOME/.config/zenborg-backup-utility"
CONFIG_FILE="$CONFIG_DIR/config.conf"
MOUNT_POINT="$HOME/Borg_Mount"

# Default configuration values
DEFAULT_BACKUP_DEST="$HOME/BorgBackupRepo"
DEFAULT_SOURCES=("$HOME/Documents" "$HOME/Pictures")

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# Load saved configuration or initialize default
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        BACKUP_DEST="$DEFAULT_BACKUP_DEST"
        SOURCE_FOLDERS=("${DEFAULT_SOURCES[@]}")
        save_config
    fi
}

save_config() {
    cat <<EOF > "$CONFIG_FILE"
# ZenBORG Backup Utility Configuration File
BACKUP_DEST="$(printf '%q' "$BACKUP_DEST")"
SOURCE_FOLDERS=($(for dir in "${SOURCE_FOLDERS[@]}"; do printf '%q ' "$dir"; done))
EOF
}

load_config

# ==========================================
# DIAGNOSTIC & INSTALLATION HELPERS
# ==========================================
get_borg_status() {
    if ! command -v borg >/dev/null 2>&1; then
        echo "<b>Status:</b> 🔴 <span foreground='red'>Borg is Not Installed</span>"
        return
    fi

    local version
    version=$(borg --version | awk '{print $2}')
    
    local running="🟢 Idle"
    if pgrep -x "borg" >/dev/null; then
        running="🟠 <span foreground='orange'>Active (Backing up...)</span>"
    fi

    local repo_status="📂 Uninitialized"
    if [ -d "$BACKUP_DEST" ]; then
        repo_status="🛡️ Ready"
    fi

    echo "<b>Engine:</b> Borg v$version  |  <b>Process:</b> $running  |  <b>Vault:</b> $repo_status"
}

ensure_borg_installed() {
    if command -v borg >/dev/null 2>&1; then
        return 0
    fi

    local install_cmd=""
    local pkg_manager=""
    local pkg_name="borgbackup" 

    # Probe system for active package managers dynamically
    if command -v apt-get >/dev/null 2>&1; then
        pkg_manager="APT"
        install_cmd="apt-get update -y && apt-get install -y borgbackup xclip"
    elif command -v pacman >/dev/null 2>&1; then
        pkg_manager="Pacman"
        pkg_name="borg" 
        install_cmd="pacman -Sy --noconfirm borg xclip"
    elif command -v dnf >/dev/null 2>&1; then
        pkg_manager="DNF"
        install_cmd="dnf install -y borgbackup xclip"
    elif command -v zypper >/dev/null 2>&1; then
        pkg_manager="Zypper"
        install_cmd="zypper --non-interactive install borgbackup xclip"
    elif command -v emerge >/dev/null 2>&1; then
        pkg_manager="Portage (Gentoo)"
        pkg_name="app-backup/borgbackup"
        install_cmd="emerge --ask=n app-backup/borgbackup x11-misc/xclip"
    elif command -v apk >/dev/null 2>&1; then
        pkg_manager="APK (Alpine)"
        install_cmd="apk add --no-cache borgbackup xclip"
    elif command -v eopkg >/dev/null 2>&1; then
        pkg_manager="Eopkg (Solus)"
        install_cmd="eopkg install -y borgbackup xclip"
    elif command -v xbps-install >/dev/null 2>&1; then
        pkg_manager="XBPS (Void)"
        install_cmd="xbps-install -Sy borgbackup xclip"
    fi

    if [ -n "$install_cmd" ]; then
        zenity --question \
            --title="Borg Engine Missing" \
            --text="Borg Backup is not installed on this system.\n\nWe detected your system utilizes the <b>$pkg_manager</b> package manager.\n\nWould you like the app to automatically install <b>$pkg_name</b> and <b>xclip</b> now?" \
            --icon-name="system-software-install" \
            --width=450 --no-wrap
    else
        zenity --warning \
            --title="Borg Engine Missing" \
            --text="Borg Backup is not installed, and your system's package manager could not be auto-detected.\n\nPlease install 'borgbackup' (or 'borg') and 'xclip' manually to use this dashboard." \
            --width=400
        return 1
    fi

    if [ $? -eq 0 ]; then
        (
            echo "10"
            echo "# Authenticating security policies..."
            pkexec sh -c "$install_cmd" 2>&1
        ) | zenity --progress \
            --title="Universal Installer" \
            --width=450 \
            --pulsate \
            --auto-close

        if command -v borg >/dev/null 2>&1; then
            zenity --info --title="Success" --text="Borg Backup installed successfully!" --icon-name="emblem-success" --width=300
            return 0
        else
            zenity --error --title="Installation Failed" \
                --text="The installation script exited, but the 'borg' command is still not accessible.\n\nPlease make sure your user has administrative privileges." \
                --width=400
            return 1
        fi
    else
        return 1
    fi
}

check_and_init_repo() {
    if [ ! -d "$BACKUP_DEST" ] && [[ "$BACKUP_DEST" != *":"* ]]; then
        zenity --question \
            --title="Initialize Repository" \
            --text="The selected backup destination does not exist:\n<b>$BACKUP_DEST</b>\n\nWould you like to build and initialize it as a new secure vault?" \
            --icon-name="folder-new" \
            --width=450 --no-wrap
        
        if [ $? -eq 0 ]; then
            mkdir -p "$BACKUP_DEST"
            get_password || return 1
            export BORG_PASSPHRASE
            
            (
                echo "pulsate"
                echo "# Initializing secure repository structures..."
                borg init --encryption=repokey "$BACKUP_DEST" 2>&1
            ) | zenity --progress --title="Initializing Borg Repo" --width=400 --pulsate --auto-close
            
            if [ ${PIPESTATUS[0]} -eq 0 ]; then
                zenity --info --title="Success" --text="Repository initialized successfully!" --icon-name="emblem-success" --width=300
            else
                zenity --error --title="Error" --text="Failed to initialize repository." --width=300
                rmdir "$BACKUP_DEST" 2>/dev/null
                return 1
            fi
        else
            return 1
        fi
    fi
    return 0
}

get_password() {
    if [ -z "$BORG_PASSPHRASE" ]; then
        BORG_PASSPHRASE=$(zenity --entry \
            --title="Borg Security Access" \
            --text="Enter your secure Repository Password:" \
            --hide-text \
            --icon-name="dialog-password" \
            --width=350)
        
        if [ $? -ne 0 ] || [ -z "$BORG_PASSPHRASE" ]; then
            zenity --error --title="Security Refused" --text="A valid master password is required to complete this action." --width=350
            return 1
        fi
        export BORG_PASSPHRASE
    fi
    return 0
}

# ==========================================
# INTERACTIVE ABOUT & HELP MANUALS
# ==========================================
show_about_dialog() {
    zenity --info \
        --title="About ZenBORG" \
        --text="<b>ZenBORG Backup Utility (v1.0)</b>\n\nA peaceful, local, deduplicated, and highly secure backup wrapper built on Borg and Zenity.\n\n<b>Developer:</b> Kay Lohn\n<b>AI Collaborator:</b> GeminiAI\n\n© 2026 - Data Sovereignty Guaranteed" \
        --width=380 --ok-label="Close"
}

show_help_manual() {
    HELP_FILE=$(mktemp)
    cat <<EOF > "$HELP_FILE"
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
EOF

    zenity --text-info \
        --title="ZenBORG Help & Reference" \
        --filename="$HELP_FILE" \
        --font="Monospace 10" \
        --width=650 --height=550 \
        --ok-label="Close Reference" 2>/dev/null
    
    rm -f "$HELP_FILE"
}

# ==========================================
# CONFIGURATION DASHBOARD
# ==========================================
configure_backup_directories() {
    while true; do
        local list_items=()
        list_items+=("📁 Repository Path" "$BACKUP_DEST")
        
        for folder in "${SOURCE_FOLDERS[@]}"; do
            list_items+=("📂 Backup Source" "$folder")
        done
        
        list_items+=("➕ Add Source Folder" "[Add new folder to the backup set]")

        # CRITICAL FIX: Added '--print-column=ALL' so Zenity returns "Column1|Column2"
        CFG_CHOICE=$(zenity --list \
            --title="Configuration Panel" \
            --column="Element" --column="Active Path / Tooltip Description" \
            --print-column=ALL \
            --width=650 --height=400 \
            --text="Double-click any entry to modify, delete, or add directories:" \
            "${list_items[@]}" \
            --ok-label="Modify" --cancel-label="Back")

        if [ $? -ne 0 ] || [ -z "$CFG_CHOICE" ]; then
            break
        fi

        # Safely split the Zenity pipe output into Category and Value
        IFS='|' read -r col_category col_path <<< "$CFG_CHOICE"

        case "$col_category" in
            "📁 Repository Path")
                REPO_ACTION=$(zenity --list \
                    --title="Repository Options" \
                    --column="Option" --column="Description" \
                    --width=480 --height=250 \
                    --hide-column=1 \
                    "SELECT" "Switch to an existing Borg folder" \
                    "CREATE" "Create and initialize a brand-new Vault")

                if [ $? -eq 0 ]; then
                    if [ "$REPO_ACTION" = "SELECT" ]; then
                        NEW_DEST=$(zenity --file-selection \
                            --directory \
                            --title="Select Existing Repository Folder" \
                            --filename="$BACKUP_DEST")
                        if [ $? -eq 0 ] && [ -n "$NEW_DEST" ]; then
                            BACKUP_DEST="$NEW_DEST"
                            save_config
                        fi
                    elif [ "$REPO_ACTION" = "CREATE" ]; then
                        NEW_VAULT_DIR=$(zenity --file-selection \
                            --directory \
                            --title="Select/Create empty folder for your new Vault")
                        
                        if [ $? -eq 0 ] && [ -n "$NEW_VAULT_DIR" ]; then
                            if [ "$(ls -A "$NEW_VAULT_DIR" 2>/dev/null)" ]; then
                                zenity --warning \
                                    --title="Folder Occupied" \
                                    --text="Borg requires a clean, empty folder to construct a secure repository layout." \
                                    --width=400
                                continue
                            fi

                            PASS1=$(zenity --entry --title="Create Vault" --text="Create Master Password:" --hide-text --width=350)
                            [ $? -ne 0 ] || [ -z "$PASS1" ] && continue

                            PASS2=$(zenity --entry --title="Confirm Password" --text="Confirm Master Password:" --hide-text --width=350)
                            [ $? -ne 0 ] && continue

                            if [ "$PASS1" != "$PASS2" ]; then
                                zenity --error --title="Mismatch" --text="Passwords did not match. Aborting vault creation." --width=350
                                continue
                            fi

                            export BORG_PASSPHRASE="$PASS1"
                            (
                                echo "pulsate"
                                echo "# Creating secure deduplicated key architectures..."
                                borg init --encryption=repokey "$NEW_VAULT_DIR" 2>&1
                            ) | zenity --progress --title="Initializing Fresh Repo" --width=400 --pulsate --auto-close

                            if [ ${PIPESTATUS[0]} -eq 0 ]; then
                                BACKUP_DEST="$NEW_VAULT_DIR"
                                save_config
                                zenity --info --title="Vault Initialized" --text="A fresh secure repository has been created successfully!" --icon-name="emblem-success" --width=450
                            else
                                zenity --error --title="Initialization Failed" --text="Failed to initialize the repository. Ensure folder is writable." --width=400
                            fi
                        fi
                    fi
                fi
                ;;

            "➕ Add Source Folder")
                NEW_DIR=$(zenity --file-selection --directory --title="Select Folder to Back Up")
                if [ $? -eq 0 ] && [ -n "$NEW_DIR" ]; then
                    local exists=false
                    for folder in "${SOURCE_FOLDERS[@]}"; do
                        [[ "$folder" == "$NEW_DIR" ]] && exists=true
                    done
                    if [ "$exists" = false ]; then
                        SOURCE_FOLDERS+=("$NEW_DIR")
                        save_config
                    else
                        zenity --warning --title="Duplicate" --text="This folder is already in your backup list." --width=300
                    fi
                fi
                ;;

            "📂 Backup Source")
                # Locate the exact index of the clicked path inside our folder array
                local matched_index=-1
                for i in "${!SOURCE_FOLDERS[@]}"; do
                    if [[ "${SOURCE_FOLDERS[$i]}" == "$col_path" ]]; then
                        matched_index=$i
                        break
                    fi
                done

                if [ "$matched_index" -ne -1 ]; then
                    # Double-click "Action Prompt" context menu replacement
                    ACTION_PROMPT=$(zenity --list \
                        --title="Manage Backup Source" \
                        --text="Choose an action for:\n<b>$col_path</b>" \
                        --column="Action" --column="Description" \
                        --width=450 --height=220 \
                        --hide-column=1 \
                        "EDIT" "✏️  Edit / Change Folder Path" \
                        "DELETE" "❌  Delete from Backup List")

                    if [ $? -eq 0 ]; then
                        if [ "$ACTION_PROMPT" = "EDIT" ]; then
                            EDITED_DIR=$(zenity --file-selection \
                                --directory \
                                --title="Select New Replacement Folder" \
                                --filename="$col_path")
                            if [ $? -eq 0 ] && [ -n "$EDITED_DIR" ]; then
                                SOURCE_FOLDERS[$matched_index]="$EDITED_DIR"
                                save_config
                            fi
                        elif [ "$ACTION_PROMPT" = "DELETE" ]; then
                            zenity --question \
                                --title="Confirm Deletion" \
                                --text="Are you sure you want to stop backing up this folder?\n\n<b>$col_path</b>" \
                                --icon-name="edit-delete" \
                                --width=400
                            
                            if [ $? -eq 0 ]; then
                                unset 'SOURCE_FOLDERS[matched_index]'
                                # Re-index the array to prevent sparse gaps in memory
                                SOURCE_FOLDERS=("${SOURCE_FOLDERS[@]}")
                                save_config
                            fi
                        fi
                    fi
                fi
                ;;
        esac
    done
}

# ==========================================
# VIEW ARCHIVES
# ==========================================
view_archives() {
    ensure_borg_installed || return 1
    check_and_init_repo || return 1
    get_password || return 1

    local archive_list
    archive_list=$(borg list "$BACKUP_DEST" 2>&1)

    if [ $? -ne 0 ]; then
        zenity --error --title="Error Reading Repo" --text="Could not fetch archive list:\n\n$archive_list" --width=400
        return 1
    fi

    if [ -z "$archive_list" ]; then
        zenity --info --title="Empty Repository" --text="No backup archives found in this repository yet." --width=350
        return 0
    fi

    local table_items=()
    while read -r name date time hash; do
        [ -z "$name" ] && continue
        table_items+=("📦 $name" "$date $time" "$hash")
    done <<< "$archive_list"

    zenity --list \
        --title="Repository Archives" \
        --column="Archive Name" --column="Creation Date" --column="ID Hash" \
        --width=650 --height=400 \
        "${table_items[@]}"
}

# ==========================================
# MOUNT/UNMOUNT REPOSITORY
# ==========================================
toggle_mount_repo() {
    ensure_borg_installed || return 1
    check_and_init_repo || return 1

    if mountpoint -q "$MOUNT_POINT" 2>/dev/null || mount | grep "$MOUNT_POINT" >/dev/null; then
        (
            echo "pulsate"
            echo "# Safely unmounting virtual file system..."
            borg umount "$MOUNT_POINT" 2>/dev/null
            if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
                fusermount -u -z "$MOUNT_POINT" 2>/dev/null || umount -l "$MOUNT_POINT" 2>/dev/null
            fi
        ) | zenity --progress --title="Unmounting Vault" --width=350 --pulsate --auto-close
        
        zenity --info --title="Unmounted" --text="The backup repository has been safely unmounted." --icon-name="emblem-success" --width=300
    else
        get_password || return 1
        mkdir -p "$MOUNT_POINT"

        (
            echo "pulsate"
            echo "# Mounting backup vault as interactive folder..."
            borg mount "$BACKUP_DEST" "$MOUNT_POINT" 2>&1
        ) | zenity --progress --title="Mounting Vault" --width=350 --pulsate --auto-close

        if mountpoint -q "$MOUNT_POINT"; then
            zenity --question \
                --title="Vault Mounted" \
                --text="Your backup vault is now live at:\n<b>$MOUNT_POINT</b>\n\nWould you like to open it in your File Manager now?" \
                --icon-name="folder" \
                --width=450
            if [ $? -eq 0 ]; then
                xdg-open "$MOUNT_POINT" &
            fi
        else
            zenity --error --title="Mount Failed" --text="Could not mount repository. Ensure FUSE utilities are configured." --width=400
        fi
    fi
}

# ==========================================
# RUN BACKUP PROCESS
# ==========================================

run_backup() {
    ensure_borg_installed || return 1
    
    if [ "${#SOURCE_FOLDERS[@]}" -eq 0 ]; then
        zenity --error --title="No Sources Selected" --text="Your backup list is empty." --width=350
        return 1
    fi
    
    check_and_init_repo || return 1
    get_password || return 1

    FULL_LOG=$(mktemp)
    SUMMARY_FILE=$(mktemp)
    ARCHIVE_NAME="Backup-$(date +%Y-%m-%d-%H%M%S)"
    export BORG_PASSPHRASE

    # 1. Run backup with --progress to standard error
    # We pipe the output so we can capture it for both the log and the progress bar
    borg create --stats --progress "$BACKUP_DEST"::"$ARCHIVE_NAME" "${SOURCE_FOLDERS[@]}" > "$FULL_LOG" 2>&1 &
    BORG_PID=$!

 # 2. Advanced Progress Parser
    # Removing numeric inputs (0, 100) ensures the progress bar remains in 'pulsate' mode
    (
        while kill -0 $BORG_PID 2>/dev/null; do
            # Get the last line of the log, removing carriage returns
            CURRENT_LINE=$(tail -n 1 "$FULL_LOG" | tr '\r' '\n' | tail -n 1)
            
            # If the line contains a file path, show it
            if [[ "$CURRENT_LINE" == *"/"* ]]; then
                # Truncate long paths for the dialog window
                DISPLAY_NAME=$(echo "$CURRENT_LINE" | rev | cut -d' ' -f1 | rev | cut -c -40)
                echo "# Processing: ...$DISPLAY_NAME"
            else
                echo "# Backing up data... please wait."
            fi
            sleep 0.5
        done
    ) | zenity --progress --title="ZenBORG Backup" --width=500 --pulsate --auto-close

    wait $BORG_PID
    
    # 3. Create a clean Summary
    sed -n '/---/,$p' "$FULL_LOG" > "$SUMMARY_FILE"

    # 4. Display Window
    while true; do
        zenity --text-info \
            --title="Backup Successful" \
            --filename="$SUMMARY_FILE" \
            --width=600 --height=400 \
            --font="Monospace 10" \
            --ok-label="Close" \
            --cancel-label="Copy Full Log"
        
        if [ "$?" -eq 1 ]; then
            if command -v xclip >/dev/null 2>&1; then
                xclip -selection clipboard < "$FULL_LOG"
            elif command -v wl-copy >/dev/null 2>&1; then
                wl-copy < "$FULL_LOG"
            fi
            zenity --info --title="Copied" --text="Full log copied to clipboard!" --timeout=2
            continue
        else
            break
        fi
    done

    rm -f "$FULL_LOG" "$SUMMARY_FILE"
}

# ==========================================
# MAIN DASHBOARD LOOP
# ==========================================
# Quietly check if Borg is installed at startup
ensure_borg_installed

while true; do
    # 1. Grab fresh details for our live dashboard header
    DIAGNOSTICS=$(get_borg_status)

    # 2. Determine mount toggle menu text dynamically
    IS_MOUNTED=false
    MOUNT_LABEL="🔌 Mount Vault as Folder"
    MOUNT_SUB="Exposes all snapshots at ~/Borg_Mount for browsing"
    
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null || mount | grep "$MOUNT_POINT" >/dev/null; then
        MOUNT_LABEL="🔌 Unmount Active Vault"
        MOUNT_SUB="Safely disconnect ~/Borg_Mount folder before ejecting"
        IS_MOUNTED=true
    fi

    # 3. Open main dashboard
    CHOICE=$(zenity --list \
        --title="ZenBORG Backup Dashboard" \
        --text="$DIAGNOSTICS" \
        --column="Option" --column="Action" --column="Tooltip & Description" \
        --width=680 --height=410 \
        --ok-label="Select" \
        --cancel-label="Exit" \
        --extra-button="About" \
        "1" "⚙️ Configuration" "Manage backup sources and the repository destination path" \
        "2" "📁 View Archives" "List and inspect completed backups/snapshots inside the vault" \
        "3" "$MOUNT_LABEL" "$MOUNT_SUB" \
        "4" "🛡️ Check Repository Integrity" "Scan files for corruption and release active transaction locks" \
        "5" "🚀 Run Backup Now" "Execute an incremental, deduplicated, and compressed backup" \
        "6" "📖 Help & Reference Manual" "Open the full built-in documentation database" \
        --hide-column=1)

    ZENITY_STATUS=$?

    # 4. Handle "About" Extra Button
    if [ "$CHOICE" = "About" ]; then
        show_about_dialog
        continue
    fi

    # 5. Handle Exit, Cancel, or Escape Keystrokes Safely
    if [ $ZENITY_STATUS -ne 0 ]; then
        if [ "$IS_MOUNTED" = true ]; then
            EXIT_PROMPT=$(zenity --list \
                --title="Active Vault Connected" \
                --text="Your secure backup vault is currently mounted at <b>~/Borg_Mount</b>.\nExiting now requires action:" \
                --column="Option" --column="Select Action" \
                --width=500 --height=220 \
                --hide-column=1 \
                "UNMOUNT" "Safely Unmount and Exit Now" \
                "KEEP" "Keep Folder Mounted and Exit" \
                "CANCEL" "Do Not Exit (Return to Dashboard)")
            
            case "$EXIT_PROMPT" in
                "UNMOUNT")
                    (
                        echo "pulsate"
                        echo "# Safely disconnecting virtual vault filesystem..."
                        borg umount "$MOUNT_POINT" 2>/dev/null
                        if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
                            fusermount -u -z "$MOUNT_POINT" 2>/dev/null || umount -l "$MOUNT_POINT" 2>/dev/null
                        fi
                    ) | zenity --progress --title="Unmounting Vault" --width=350 --pulsate --auto-close
                    break
                    ;;
                "KEEP")
                    break
                    ;;
                *)
                    continue
                    ;;
            esac
        else
            zenity --question \
                --title="Exit Confirmation" \
                --text="Are you sure you want to exit the ZenBORG Backup Dashboard?" \
                --icon-name="application-exit" \
                --width=350
            if [ $? -eq 0 ]; then
                break
            else
                continue
            fi
        fi
    fi

    # Process menu choices
    case "$CHOICE" in
        "1"|"⚙️ Configuration")
            configure_backup_directories
            ;;
        "2"|"📁 View Archives")
            view_archives
            ;;
        "3"|"$MOUNT_LABEL")
            toggle_mount_repo
            ;;
        "4"|"🛡️ Check Repository Integrity")
            ensure_borg_installed || continue
            check_and_init_repo || continue
            get_password || continue
            
            (
                echo "pulsate"
                echo "# Verifying archive integrity with secure engine..."
                borg check "$BACKUP_DEST" 2>&1
            ) | zenity --progress --title="Borg Check" --width=450 --pulsate --auto-close
                
            if [ ${PIPESTATUS[0]} -eq 0 ]; then
                zenity --info --title="Integrity Clean" --text="No issues found. Your archives are fully secure!" --icon-name="emblem-success" --width=350
            else
                zenity --error --title="Integrity Failed" --text="Borg detected issues or check was interrupted." --width=350
            fi
            ;;
        "5"|"🚀 Run Backup Now")
            run_backup
            ;;
        "6"|"📖 Help & Reference Manual")
            show_help_manual
            ;;
    esac
done

# ==========================================
# GRACEFUL SILENT EXIT
# ==========================================
rm -f "$STATS_FILE" "$BORG_LOG" 2>/dev/null
exit 0
