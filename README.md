# Fujitsu FMV Lifebook U9311 ACPI Patch for Linux
Applying ACPI Patch for Fujitsu FMV Lifebook U9311 for Linux.

The newest version of this software can be found at [GitHub](https://github.com/suikan4github/u9311-acpi-patch).

## Details
This software applies an ACPI patch to the Fujitsu FMV Lifebook U9311 to fix the screen blackout issue when the device is resumed from the suspend state. 

This problem is caused by the wrong handling of the LCD display in the ACPI tables, which leads to the display not being properly re-initialized after resuming from suspend.

This problem and workaround is explained in the [Fujitsu LIFEBOOK U9311](https://wiki.archlinux.org/title/Fujitsu_Lifebook_U9311) page in the Arch Linux Wiki.

The script in this repository is based on the workaround described in the Arch Linux Wiki.

## Supported Distributions
- Fedora Workstation
- Fedora Atomic Desktop
- Ubuntu Desktop

### Tested Versions and Hardware
| Distribution      | Version |
|-------------      | ------- |
| Fedora KDE Plasma | 44 |
| Fedora Kinoite    | 44 |
| Ubuntu            | 25.10     |
| Ubuntu            | 26.04 LTS |

- Fujitsu LIFEBOOK WU-X/E3 Intel Core i5 1135G7 ( Equivalent to U9311 ).

## Usage
Run the following command to apply the ACPI patch:
```sh
./apply-patch.sh
```
If the ACPI table has mismatch with the patch, script will exit with error. 
## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
