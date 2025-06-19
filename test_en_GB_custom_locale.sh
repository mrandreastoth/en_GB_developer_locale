#!/bin/bash
set -e

LOCALE="en_GB_custom.utf8"

echo "→ Verifying that locale is available..."
locale -a | grep -q "$LOCALE" || { echo "❌ Locale $LOCALE not available"; exit 1; }
echo "✅ Locale $LOCALE is available"

echo
echo "→ Testing date/time formatting with offset..."
echo "Command: LC_ALL=$LOCALE date --date='2025-06-19 14:30:00' +\"%c\""
echo -n "Output:  "
LC_ALL=$LOCALE date --date='2025-06-19 14:30:00' +"%c"
echo "Expected: 2025-06-19 14:30:00 CEST"
echo

echo "→ Testing number formatting (thousands separator)..."
echo "Command: LC_ALL=$LOCALE printf \"%'.2f\\n\" 1234567.89"
echo -n "Output:  "
LC_ALL=$LOCALE printf "%'.2f\n" 1234567.89
echo "Expected: 1,234,567.89"
echo

echo "→ Testing currency formatting..."
echo "Command: LC_ALL=$LOCALE locale -k LC_MONETARY | grep -E 'currency_symbol|int_curr_symbol'"
LC_ALL=$LOCALE locale -k LC_MONETARY | grep -E 'currency_symbol|int_curr_symbol'
echo "Expected: currency_symbol=\"$\""
echo "          int_curr_symbol=\"USD \""
echo

echo "→ Testing yes/no expression parsing..."
echo "Command: yes_output=\$(LC_ALL=$LOCALE bash -c 'read -p \"yes? \" x; echo \$x' <<< \"y\")"
yes_output=$(LC_ALL=$LOCALE bash -c 'read -p "yes? " x; echo $x' <<< "y")
echo "Output:   $yes_output"
echo "Expected: y"
echo

echo "→ Testing measurement system..."
measure=$(LC_ALL=$LOCALE locale measurement)
echo "Output:   $measure"
echo "Expected: 1 (metric)"
echo

echo "→ Testing paper size (A4)..."
echo "Command: LC_ALL=$LOCALE locale -k LC_PAPER | grep -E 'height|width'"
LC_ALL=$LOCALE locale -k LC_PAPER | grep -E 'height|width'
echo "Expected: height=297"
echo "          width=210"
echo

echo "→ Testing address format country codes..."
echo "Command: LC_ALL=$LOCALE locale -k LC_ADDRESS | grep -E 'country_ab2|country_ab3|country_car'"
LC_ALL=$LOCALE locale -k LC_ADDRESS | grep -E 'country_ab2|country_ab3|country_car'
echo "Expected: country_ab2=\"GB\""
echo "          country_ab3=\"GBR\""
echo "          country_car=\"GB\""
echo

echo "✔ All tests complete. Visually compare output with expected values above."
