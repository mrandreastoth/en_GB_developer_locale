#!/bin/bash
# Check that the current environment produces the formats locale.env aims for,
# both through glibc and (if PyQt6 is installed) through Qt/CLDR as KDE apps see it.
# Run it in a fresh login session after apply_locale.sh.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=locale.env
source "$SCRIPT_DIR/locale.env"

pass=0 fail=0

check() {
    local name="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        printf '  ✅ %-34s %s\n' "$name" "$actual"
        pass=$((pass + 1))
    else
        printf '  ❌ %-34s got %q, expected %q\n' "$name" "$actual" "$expected"
        fail=$((fail + 1))
    fi
}

echo "Environment:"
check "LANG"           "$LOCALE_LANG"        "${LANG:-}"
check "LC_TIME"        "$LOCALE_TIME"        "${LC_TIME:-}"
check "LC_MONETARY"    "$LOCALE_MONETARY"    "${LC_MONETARY:-}"
check "LC_MEASUREMENT" "$LOCALE_MEASUREMENT" "${LC_MEASUREMENT:-}"
check "LC_ALL is unset" "" "${LC_ALL:-}"
for var in LC_NUMERIC LC_COLLATE LC_CTYPE LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_IDENTIFICATION; do
    check "$var unset (falls back to LANG)" "" "${!var:-}"
done

echo
echo "Locales available:"
available="$(locale -a)"
for loc in $(printf '%s\n' "$LOCALE_LANG" "$LOCALE_TIME" "$LOCALE_MONETARY" "$LOCALE_MEASUREMENT" | sort -u); do
    # locale -a usually lists normalised names (en_GB.utf8), so accept either spelling.
    if grep -qixE "${loc%%.*}\.(utf8|utf-8)" <<<"$available"; then
        check "$loc generated" yes yes
    else
        check "$loc generated" yes no
    fi
done

echo
echo "glibc formatting:"
when='2025-06-19 14:30:00'
check "date (%x)"                "2025-06-19"           "$(date -d "$when" +%x)"
check "time (%X)"                "14:30:00"             "$(date -d "$when" +%X)"
check "first weekday (1=Sun)"    "2"                    "$(locale first_weekday)"
check "week rule (4 = ISO 8601)" "4"                    "$(locale -k week-1stweek | cut -d= -f2)"
check "month name"               "June"                 "$(date -d "$when" +%B)"
check "number grouping"          "1,234,567.89"         "$(printf "%'.2f" 1234567.89)"
check "currency symbol"          '"$"'                  "$(locale -k currency_symbol | cut -d= -f2)"
check "international currency"   '"USD "'               "$(locale -k int_curr_symbol | cut -d= -f2)"
check "measurement (1=metric)"   "1"                    "$(locale measurement | head -1)"
check "paper height (A4)"        "297"                  "$(locale height)"
check "yes/no (from en_GB)"      '"^[+1yY]"'            "$(locale -k yesexpr | cut -d= -f2)"

# Known glibc bug: en_SE's d_t_fmt uses %:z, which strftime() doesn't support, so %c
# prints a literal "%:z". The date command handles it; C/Python/Perl strftime don't.
c_out="$(python3 -I -c "import locale,time; locale.setlocale(locale.LC_ALL, ''); print(time.strftime('%c', time.strptime('$when', '%Y-%m-%d %H:%M:%S')))" 2>&1)"
echo "  ⚠️  known issue: strftime %c → $c_out"

echo
if python3 -I -c 'import PyQt6' 2>/dev/null; then
    echo "Qt/CLDR formatting (what KDE apps show):"
    while IFS='|' read -r name expected actual; do
        check "$name" "$expected" "$actual"
    done < <(python3 -I - <<'EOF'
from PyQt6.QtCore import QLocale, QDate, QTime
l = QLocale.system()
d, t = QDate(2025, 6, 19), QTime(14, 30)
print(f"short date|2025-06-19|{l.toString(d, QLocale.FormatType.ShortFormat)}")
print(f"short time|14:30|{l.toString(t, QLocale.FormatType.ShortFormat)}")
print(f"first day of week|Monday|{l.firstDayOfWeek().name}")
print(f"number|1,234,567.89|{l.toString(1234567.89, 'f', 2)}")
print(f"currency|$1,234,567.89|{l.toCurrencyString(1234567.89)}")
print(f"measurement|MetricSystem|{l.measurementSystem().name}")
EOF
)
else
    echo "Qt/CLDR formatting: skipped (install python-pyqt6 to check what KDE apps show)"
fi

echo
echo "Result: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
