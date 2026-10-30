#!/bin/bash
# Undo apply_locale.sh: restore the system locale and Plasma region settings
# from the backups it made. Locales enabled in /etc/locale.gen are left in place.
#
# Run as your normal user; the system-wide steps use sudo.
set -euo pipefail

LOCALE_CONF_BACKUP=/etc/locale.conf.pre-locale-setup
PLASMA_RC="$HOME/.config/plasma-localerc"
PLASMA_RC_BACKUP="$HOME/.config/plasma-localerc.pre-locale-setup"

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user (not with sudo); it calls sudo itself." >&2
    exit 1
fi

if [[ -e "$LOCALE_CONF_BACKUP" ]]; then
    echo "→ Restoring system locale from $LOCALE_CONF_BACKUP..."
    # Copy the file back rather than using "localectl set-locale", which merges with the
    # current settings and would leave this setup's LC_* values in place.
    sudo mv -f "$LOCALE_CONF_BACKUP" /etc/locale.conf
    sed 's/^/   /' /etc/locale.conf
else
    echo "→ No system backup found ($LOCALE_CONF_BACKUP); skipping."
fi

if [[ -e "$PLASMA_RC_BACKUP" ]]; then
    echo "→ Restoring Plasma region settings from $PLASMA_RC_BACKUP..."
    if [[ -s "$PLASMA_RC_BACKUP" ]]; then
        mv -f "$PLASMA_RC_BACKUP" "$PLASMA_RC"
    else
        # There was no plasma-localerc before; remove the one apply_locale.sh created.
        rm -f "$PLASMA_RC" "$PLASMA_RC_BACKUP"
    fi
else
    echo "→ No Plasma backup found ($PLASMA_RC_BACKUP); skipping."
fi

echo "→ Done. Log out and back in (or reboot) for the change to take effect."
