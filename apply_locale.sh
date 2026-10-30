#!/bin/bash
# Apply the locale combination from locale.env system-wide (glibc/systemd) and,
# on KDE Plasma, to the current user's Plasma session.
#
# Run as your normal user; the system-wide steps use sudo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=locale.env
source "$SCRIPT_DIR/locale.env"

LOCALE_GEN=/etc/locale.gen
LOCALE_CONF=/etc/locale.conf
LOCALE_CONF_BACKUP=/etc/locale.conf.pre-locale-setup
PLASMA_RC="$HOME/.config/plasma-localerc"
PLASMA_RC_BACKUP="$HOME/.config/plasma-localerc.pre-locale-setup"
PLASMA_LC_KEYS=(LC_NUMERIC LC_TIME LC_MONETARY LC_MEASUREMENT LC_COLLATE LC_CTYPE
                LC_PAPER LC_ADDRESS LC_NAME LC_TELEPHONE)

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user (not with sudo); it calls sudo itself." >&2
    exit 1
fi

# Make sure "<locale> UTF-8" is an active line in /etc/locale.gen.
ensure_locale_gen_entry() {
    local loc="$1" esc="${1//./\\.}"
    if grep -qE "^${esc}[[:space:]]+UTF-8" "$LOCALE_GEN"; then
        echo "   ${loc}: already enabled"
    elif grep -qE "^#[[:space:]]*${esc}[[:space:]]+UTF-8" "$LOCALE_GEN"; then
        sudo sed -i -E "s/^#[[:space:]]*(${esc}[[:space:]]+UTF-8)/\1/" "$LOCALE_GEN"
        echo "   ${loc}: enabled"
    else
        echo "${loc} UTF-8" | sudo tee -a "$LOCALE_GEN" >/dev/null
        echo "   ${loc}: added"
    fi
}

echo "→ Removing the legacy en_GB_custom / en_GB@custom locale, if present..."
for f in /usr/share/i18n/locales/en_GB_custom /usr/share/i18n/locales/en_GB@custom; do
    if [[ -e "$f" ]]; then sudo rm -f "$f"; echo "   removed $f"; fi
done
if grep -qE '^en_GB(_|@)custom' "$LOCALE_GEN"; then
    sudo sed -i -E '/^en_GB(_|@)custom/d' "$LOCALE_GEN"
    echo "   removed legacy entries from $LOCALE_GEN"
fi

echo "→ Enabling required locales in $LOCALE_GEN..."
for loc in $(printf '%s\n' "$LOCALE_LANG" "$LOCALE_TIME" "$LOCALE_MONETARY" "$LOCALE_MEASUREMENT" | sort -u); do
    ensure_locale_gen_entry "$loc"
done

echo "→ Generating locales..."
sudo locale-gen

if [[ ! -e "$LOCALE_CONF_BACKUP" && -e "$LOCALE_CONF" ]]; then
    echo "→ Backing up $LOCALE_CONF to $LOCALE_CONF_BACKUP..."
    sudo cp -p "$LOCALE_CONF" "$LOCALE_CONF_BACKUP"
fi

# Write the file rather than using "localectl set-locale", which merges with the existing
# settings and would leave any other LC_* overrides in place.
echo "→ Writing system locale to $LOCALE_CONF..."
printf '%s\n' \
    "LANG=$LOCALE_LANG" \
    "LC_TIME=$LOCALE_TIME" \
    "LC_MONETARY=$LOCALE_MONETARY" \
    "LC_MEASUREMENT=$LOCALE_MEASUREMENT" \
    | sudo tee "$LOCALE_CONF" >/dev/null
localectl status | sed -n '/System Locale/,/VC Keymap/p' | grep -v 'VC Keymap' | sed 's/^ */   /'

# Plasma exports its own [Formats] settings at login, overriding the system locale.
if command -v kwriteconfig6 >/dev/null && { [[ -e "$PLASMA_RC" ]] || [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]]; }; then
    echo "→ Updating Plasma region settings ($PLASMA_RC)..."
    if [[ ! -e "$PLASMA_RC_BACKUP" ]]; then
        if [[ -e "$PLASMA_RC" ]]; then cp -p "$PLASMA_RC" "$PLASMA_RC_BACKUP"; else : > "$PLASMA_RC_BACKUP"; fi
    fi
    for key in "${PLASMA_LC_KEYS[@]}"; do
        kwriteconfig6 --file plasma-localerc --group Formats --key "$key" --delete
    done
    kwriteconfig6 --file plasma-localerc --group Formats --key LANG "$LOCALE_LANG"
    kwriteconfig6 --file plasma-localerc --group Formats --key LC_TIME "$LOCALE_TIME"
    kwriteconfig6 --file plasma-localerc --group Formats --key LC_MONETARY "$LOCALE_MONETARY"
    kwriteconfig6 --file plasma-localerc --group Formats --key LC_MEASUREMENT "$LOCALE_MEASUREMENT"
    sed -n '/^\[Formats\]/,/^\[/p' "$PLASMA_RC" | sed 's/^/   /'
fi

echo "→ Checking for other places that override the locale..."
found=0
for path in /etc/environment /etc/profile.d "$HOME/.config/locale.conf" "$HOME/.config/environment.d" \
            "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.bashrc" "$HOME/.pam_environment"; do
    [[ -e "$path" ]] || continue
    # /etc/profile.d/locale.sh is Arch's loader for locale.conf, not an override.
    if grep -rnHE '^[^#]*\b(LANG|LC_[A-Z]+)=' "$path" 2>/dev/null \
            | grep -vE 'LANGUAGE=|^/etc/profile\.d/locale\.sh:'; then
        found=1
    fi
done
if [[ $found -eq 1 ]]; then
    echo "   ⚠ The lines above set locale variables and may override this setup; review them."
else
    echo "   none found"
fi

echo "→ Done. Log out and back in (or reboot), then run ./test_locale.sh"
