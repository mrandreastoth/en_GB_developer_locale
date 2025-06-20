#!/bin/bash
set -e

LOCALE_NAME="en_GB_custom"
LOCALE_UTF8="${LOCALE_NAME}.utf8"
STD_LOCALE="en_GB.UTF-8"
LOCALE_FILE="/usr/share/i18n/locales/${LOCALE_NAME}"
LOCALE_GEN_PATH="/etc/locale.gen"
USER_ENV_FILES=( ".bashrc" ".bash_profile" ".profile" ".pam_environment" ".zshrc" )
SYSTEM_ENV_FILES=(
    "/etc/environment"
    "/etc/profile"
    "/etc/profile.d"
    "/etc/locale.conf"
    "/etc/X11/xinit/xinitrc.d"
)
CONFIG_DIRS=( ".config/environment.d" )

echo "→ Checking for root privileges..."
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root."
    exit 1
fi

echo "→ Checking current system locale..."
CURRENT_LANG=$(localectl status | grep 'System Locale' | grep -o 'LANG=[^ ]*' | cut -d= -f2)
if [[ "$CURRENT_LANG" == "$LOCALE_UTF8" ]]; then
    echo "→ System locale is set to ${LOCALE_UTF8}, reverting to ${STD_LOCALE}..."
    localectl set-locale LANG="${STD_LOCALE}"
fi

echo "→ Removing locale file: ${LOCALE_FILE}"
rm -f "${LOCALE_FILE}"

echo "→ Cleaning /etc/locale.gen of any reference to ${LOCALE_NAME}..."
sed -i "/^${LOCALE_NAME}\.[Uu][Tt][Ff]-8/d" "$LOCALE_GEN_PATH"

echo "→ Regenerating locales..."
locale-gen

echo "→ Scanning system-wide environment config files..."
for path in "${SYSTEM_ENV_FILES[@]}"; do
    if [[ -f "$path" ]]; then
        grep -l "$LOCALE_NAME" "$path" | while read -r file; do
            echo "⚠️  Found reference in: $file"
            sed -i "/$LOCALE_NAME/d" "$file"
            echo "→ Removed matching lines from $file"
        done
    elif [[ -d "$path" ]]; then
        grep -lr "$LOCALE_NAME" "$path" | while read -r file; do
            echo "⚠️  Found reference in: $file"
            sed -i "/$LOCALE_NAME/d" "$file"
            echo "→ Removed matching lines from $file"
        done
    fi
done

echo "→ Scanning all user home directories..."
for userdir in /home/*; do
    [ -d "$userdir" ] || continue
    user=$(basename "$userdir")

    for file in "${USER_ENV_FILES[@]}"; do
        fullpath="$userdir/$file"
        if [[ -f "$fullpath" ]] && grep -q "$LOCALE_NAME" "$fullpath"; then
            echo "⚠️  Found locale reference in: $fullpath"
            echo "→ Previewing lines:"
            grep "$LOCALE_NAME" "$fullpath" | sed 's/^/   /'
            echo -n "→ Remove these lines from $fullpath? [y/N] "
            read -r reply
            if [[ "$reply" =~ ^[Yy]$ ]]; then
                sed -i "/$LOCALE_NAME/d" "$fullpath"
                echo "→ Lines removed."
            else
                echo "→ Left unchanged."
            fi
        fi
    done

    for config_dir in "${CONFIG_DIRS[@]}"; do
        full_config_dir="$userdir/$config_dir"
        if [[ -d "$full_config_dir" ]]; then
            grep -lr "$LOCALE_NAME" "$full_config_dir" | while read -r conf_file; do
                echo "⚠️  Found reference in: $conf_file"
                echo -n "→ Remove this file? [y/N] "
                read -r confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    rm -f "$conf_file"
                    echo "→ Removed $conf_file"
                else
                    echo "→ Left $conf_file"
                fi
            done
        fi
    done
done

echo "→ Finished locale uninstallation and cleanup."
echo "✅ Reboot or re-login recommended to fully apply changes."
