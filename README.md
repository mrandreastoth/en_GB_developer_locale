# en_GB_custom Locale

This repository provides a **custom `en_GB_custom` locale** definition for glibc-based Linux systems.

## Description

This locale combines:

- **British English** language and spelling (based on `en_GB`)
- **ISO 8601**-style date and time formatting (e.g., `2025-06-19`, `14:30:00`)
- **ISO-style address formatting**
- **US-style number and currency formatting**
  - Decimal point: `.`
  - Thousands separator: `,`
  - Currency: `$` (symbol only), using ISO formatting, not US localisation

It is designed for users who prefer British English but want to align with **international standards** and **common numerical formats** in software development, documentation, and data interchange.

## Files

- `en_GB_custom.src` – Locale definition file
- `install_en_GB_custom_locale.sh` – Installation script
- `uninstall_en_GB_custom_locale.sh` – Uninstallation and cleanup script
- `test_en_GB_custom_locale.sh` – Test script for verifying locale behavior

## Installation

```bash
chmod +x install_en_GB_custom_locale.sh
sudo ./install_en_GB_custom_locale.sh
```

This script will:

1. Copy the locale source to the correct system directory.
2. Remove any obsolete `en_GB@custom` variant if found to avoid locale conflicts.
3. Register it in `/etc/locale.gen` (if not already present).
4. Generate the locale using `locale-gen`.
5. Set it system-wide via `localectl`.

## Enabling the Locale

### Temporary (Current Terminal Only)

To enable the custom locale for just your current terminal session:

```bash
export LANG=en_GB_custom.utf8
export LC_ALL=en_GB_custom.utf8
```

This is useful for testing or scripting purposes.

### Permanent (System-Wide)

To make the locale the default across all user sessions and terminals:

```bash
sudo localectl set-locale LANG=en_GB_custom.utf8
```

After applying this, either reboot or re-login for changes to take full effect.

### Per-User Configuration

Alternatively, for just one user, add this to `~/.bashrc` or `~/.profile`:

```bash
export LANG=en_GB_custom.utf8
export LC_ALL=en_GB_custom.utf8
```

Then run:

```bash
source ~/.bashrc
```

## Testing the Locale

### Prerequisite

Before running the test script, you **must have the locale enabled in the current terminal session**, either temporarily or permanently.

### Running the Test

```bash
chmod +x test_en_GB_custom_locale.sh
./test_en_GB_custom_locale.sh
```

The script will:

- Verify that the locale is available
- Run various standard commands (`date`, `locale`, `printf`, etc.)
- Show **actual vs expected output** side-by-side for easy visual comparison

## Uninstallation

To remove the custom locale and revert to the standard `en_GB.UTF-8`:

```bash
chmod +x uninstall_en_GB_custom_locale.sh
sudo ./uninstall_en_GB_custom_locale.sh
```

This will:

- Remove the locale source file
- Clean up `/etc/locale.gen`
- Revert system-wide locale settings if `en_GB_custom` is in use
- Scan user home directories for references and offer to remove them interactively

## Troubleshooting

### Unexpected Locale Values After Reboot

If, after rebooting or logging in, your locale still defaults to `en_GB.UTF-8` or shows mixed values:

- Check for leftover lines in `~/.bash_profile`, `~/.profile`, `~/.pam_environment`, or other user environment files.
- Run:
  ```bash
  grep en_GB_custom ~/.bash* ~/.profile ~/.pam_environment
  ```
- Also inspect:
  - `/etc/environment`
  - `/etc/profile.d/`
  - `/etc/locale.conf`

These files may override `localectl` settings.

To reset the locale environment fully, use the uninstallation script and reinstall cleanly.

## Compatibility

Tested under:

- Arch Linux / EndeavourOS
- glibc-based environments

Note: This script assumes `sudo` and `locale-gen` are available. Some distributions may use different locale management systems.

## Author

Andreas Toth  
<andreas.toth@xtra.co.nz>
