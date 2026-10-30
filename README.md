# en_GB developer locale

A locale setup for glibc-based Linux systems (with KDE Plasma support) that combines:

- **British English** language, spelling, sorting and messages
- **ISO 8601** dates and times (`2025-06-19`, `14:30`), Monday as first day of the week, ISO week numbers
- **Numbers** with `.` decimal point and `,` thousands separator (`1,234,567.89`)
- **USD** currency (`$1,234,567.89`). It is a developer's locale first: this matches the
  `en_US` default of most tooling, CI images, documentation and test fixtures
- **Metric** measurements and **A4** paper

## How it works

There is no custom locale. Each part of the combination is taken from a stock locale
through the standard per-category variables:

| Variable         | Value         | Why |
|------------------|---------------|-----|
| `LANG`           | `en_GB.UTF-8` | British English; also supplies numbers, paper, address, etc. |
| `LC_TIME`        | `en_SE.UTF-8` | The stock English locale with ISO 8601 dates in both glibc and Qt/CLDR |
| `LC_MONETARY`    | `en_US.UTF-8` | USD |
| `LC_MEASUREMENT` | `en_SE.UTF-8` | Metric in both glibc and Qt (Qt treats `en_GB` as imperial) |

The values live in `locale.env`.

Earlier versions of this repo installed a custom `en_GB_custom` locale. That only worked for
programs that use glibc's locale data. Qt/KDE, Firefox, Chromium, Java, Node and other
ICU-based programs read just the locale *name* and use their own (CLDR) data, so they saw
`en_GB_custom` as plain `en_GB`. Stock per-category locales are understood by both.

## Usage

Run the scripts as your normal user; they call `sudo` for the system-wide steps.

```bash
./apply_locale.sh     # apply the setup
./test_locale.sh      # verify it (in a fresh login session)
./restore_locale.sh   # undo it
```

`apply_locale.sh`:

1. Removes the legacy `en_GB_custom` / `en_GB@custom` locale, if installed.
2. Enables the required locales in `/etc/locale.gen` and runs `locale-gen`.
3. Backs up `/etc/locale.conf` (first run only) and rewrites it with the four settings.
   (`localectl set-locale` is not used: it merges with existing settings, so other
   `LC_*` overrides would survive.)
4. On KDE Plasma, backs up and updates `~/.config/plasma-localerc`. Plasma applies its own
   region settings at login, which would otherwise override the system locale.
5. Lists any other files that set locale variables (`/etc/environment`, `~/.bashrc`,
   `~/.config/environment.d`, …) so you can review them. It does not change them.

Log out and back in (or reboot) afterwards.

`restore_locale.sh` restores `/etc/locale.conf` and `~/.config/plasma-localerc` from the
backups. Locales enabled in `/etc/locale.gen` are left in place.

`test_locale.sh` checks the environment variables, that the locales are generated, and the
actual output of glibc and (if `python-pyqt6` is installed) Qt, then reports pass/fail.

## Notes

- **Don't set `LC_ALL`.** It overrides every category and undoes the combination. For a
  one-off test in a terminal, set the variables from the table above instead.
- **Programs that only read `LANG`** (rare) get plain `en_GB`: `dd/mm/yy` dates and `£`.
- **Known glibc bug:** `en_SE`'s combined date-time format uses `%:z`, which glibc's
  `strftime()` doesn't support. `%c` in C, Python or Perl therefore prints
  `2025-06-19T14:30:00%:z`. The `date` command, `%x`/`%X` and Qt are not affected.
  `en_DK` doesn't have this bug in glibc, but in Qt/KDE it formats dates as
  `19/06/2025 14.30`, so `en_SE` is the better choice.
- Finance and spreadsheet applications may default to USD; set the currency per application
  where you need another one.

## Compatibility

Developed on CachyOS (Arch-based) with glibc 2.44 and KDE Plasma 6.8. Requires `locale-gen`
and `localectl` (systemd). The Plasma step needs `kwriteconfig6` and is skipped elsewhere.

## Author

Andreas Toth  
<andreas.toth@xtra.co.nz>
