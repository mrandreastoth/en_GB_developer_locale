#!/bin/bash
set -e

LOCALE_NAME="en_GB_custom"
LOCALE_UTF8="${LOCALE_NAME}.utf8"
LOCALE_GEN_ENTRY="${LOCALE_UTF8} UTF-8"
LOCALE_FILE="${LOCALE_NAME}.src"
LOCALE_SRC_PATH="./${LOCALE_FILE}"
LOCALE_TARGET_PATH="/usr/share/i18n/locales/${LOCALE_NAME}"
LOCALE_GEN_PATH="/etc/locale.gen"

echo "→ Checking for root privileges..."
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

echo "→ Cleaning up old 'en_GB@custom' locale if present..."
rm -f "/usr/share/i18n/locales/en_GB@custom" || true
sed -i '/^en_GB@custom\.UTF-8/d' "$LOCALE_GEN_PATH" || true

echo "→ Copying ${LOCALE_FILE} to ${LOCALE_TARGET_PATH}..."
cp -f "$LOCALE_SRC_PATH" "$LOCALE_TARGET_PATH"

echo "→ Ensuring ${LOCALE_NAME}.utf8 is present in ${LOCALE_GEN_PATH}..."
# Remove old casing variants if present
sed -i "/^${LOCALE_NAME}\.[Uu][Tt][Ff]-8/d" "$LOCALE_GEN_PATH"

# Add canonical form
echo "$LOCALE_GEN_ENTRY" >> "$LOCALE_GEN_PATH"

echo "→ Generating locales..."
locale-gen

echo "→ Setting system-wide locale via localectl..."
localectl set-locale LANG="${LOCALE_UTF8}"

echo "→ Done."
echo "→ You may need to reboot or re-login for the change to fully take effect."
echo "→ Verify with: locale && locale -a | grep ${LOCALE_NAME}"
