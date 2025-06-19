#!/bin/bash
set -e

LOCALE_NAME="en_GB_custom"
LOCALE_UTF8="$LOCALE_NAME.UTF-8"
LOCALE_FILE="en_GB_custom.src"
LOCALE_PATH="/usr/share/i18n/locales/$LOCALE_NAME"

echo "→ Checking for root privileges..."
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

echo "→ Cleaning up old @custom locale if it exists..."
rm -f /usr/share/i18n/locales/en_GB@custom || true
sed -i '/^en_GB@custom\.UTF-8/d' /etc/locale.gen || true

echo "→ Copying $LOCALE_FILE to $LOCALE_PATH"
cp "./$LOCALE_FILE" "$LOCALE_PATH"

echo "→ Ensuring $LOCALE_UTF8 is in /etc/locale.gen"
if ! grep -q "^$LOCALE_UTF8" /etc/locale.gen; then
    echo "$LOCALE_UTF8 UTF-8" >> /etc/locale.gen
    echo "→ Added $LOCALE_UTF8 to /etc/locale.gen"
else
    echo "→ $LOCALE_UTF8 already exists in /etc/locale.gen"
fi

echo "→ Generating locale..."
locale-gen

echo "→ Setting system-wide locale via localectl"
localectl set-locale LANG="$LOCALE_UTF8"

echo "→ Done!"
echo "You can verify with: locale -a"
