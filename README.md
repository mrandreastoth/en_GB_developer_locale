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
  - Currency: `$`, using `USD`

It is designed for users who prefer British English but want to align with **international standards** and **common numerical formats** in software development, documentation, and data interchange.

## Files

- `en_GB_custom.src` – Locale definition file
- `install_en_GB_custom_locale.sh` – Installation script

## Installation

Before running the installation script, ensure it is executable:

```bash
chmod +x install_en_GB_custom_locale.sh
```

Then run:

```bash
sudo ./install_en_GB_custom_locale.sh
```

This script will:

1. Copy the locale source to the correct system directory.
2. Register it in `/etc/locale.gen` (if not already present).
3. Generate the locale using `locale-gen`.
4. Set it system-wide via `localectl`.

## Verification

After installation, verify the locale with:

```bash
locale -a | grep en_GB_custom
```

And confirm system locale settings using:

```bash
locale
```

## Compatibility

Tested under:

- Arch Linux / EndeavourOS
- glibc-based environments

Note: This script assumes `sudo` and `locale-gen` are available. Some distributions may use different locale management systems.

## Author

Andreas Toth  
<andreas.toth@xtra.co.nz>
