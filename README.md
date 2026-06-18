# Fujitsu FMV Lifebook U9311 ACPI Patch for Linux
Applying ACPI Patch for Fujitsu FMV Lifebook U9311 for Linux.

The newest version of this software can be found at [GitHub](https://github.com/suikan4github/u9311-acpi-patch).

## Details
This software applies an ACPI patch to the Fujitsu FMV Lifebook U9311 to fix the screen blackout issue when the device is resumed from the suspend state. 

The root cause of this issue is the wrong handling of the LCD display power suppoly in the ACPI tables of the firmware, which leads to the display not being properly powered after resuming from suspend.

This problem and workaround are explained in the [Fujitsu LIFEBOOK U9311](https://wiki.archlinux.org/title/Fujitsu_Lifebook_U9311) page of the Arch Linux Wiki.

The scripts in this repository are based on the workaround described in the Arch Linux Wiki.

## Supported Distributions
- Fedora Workstation
- Fedora Atomic Desktop
- Ubuntu Desktop

### Tested Versions and Hardware
As of 2026/Jun/18.

| Distribution      | Version   | Result |
|-------------      | -------   |--------|
| Fedora KDE Plasma | 44        |  OK    |
| Fedora Kinoite    | 44        |  OK    |
| Ubuntu            | 25.10     |  OK    |
| Ubuntu            | 26.04 LTS |  OK    |

Hardware : 
- Fujitsu LIFEBOOK WU-X/E3 Intel Core i5 1135G7 ( Equivalent model to LIFEBOOK U9311 ).

## Usage
Run the following command to apply the ACPI patch:
```sh
./apply-patch.sh
```
If the ACPI table has mismatch with the patch, script will terminate the process and exit with error. In this case, system will be untouched. 

## Removing the patch

To remove the patch, Run the following commands:

```sh
if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "Cannot detect OS" >&2
    exit 1
fi

if [ "$ID" = "ubuntu" ] || [ "$ID_LIKE" = "*ubuntu*" ]; then
    echo "Detected Ubuntu"
    # Ubuntu: remove the GRUB line
    sudo cp /etc/default/grub /etc/default/grub.bak && \
    awk '!($0 == "GRUB_EARLY_INITRD_LINUX_CUSTOM=\"acpi_override.cpio\"")' /etc/default/grub.bak | sudo tee /etc/default/grub

    sudo update-grub


elif [ "$ID" = "fedora" ] || [ "$ID_LIKE" = "*fedora*" ]; then
    echo "Detected Fedora"
    # Fedora: remove the dracut config
    sudo mv /etc/dracut.conf.d/99-acpi-override.conf /etc/dracut.conf.d/99-acpi-override.conf.bak
    if [ -e /run/ostree-booted ]; then
        echo "[fedora] Detected Fedora Atomic Desktop. Regenerating the initramfs using rpm-ostree..."
        sudo rpm-ostree initramfs --disable
        sudo rpm-ostree initramfs --enable
    else
        # Fedora Workstation / Spin 
        echo "[fedora] Detected Fedora Workstation / Spin. Regenerating the initramfs using dracut..."
        sudo dracut --force --verbose
    fi

else
    echo "Unsupported distro: $ID" >&2
    exit 1
fi

```
Above commands will remove the configuration to read the ACPI Patch. After rebooting, system will be back to the original state without ACPI patch.




### Ubuntu
Run the following commands : 
```sh
```

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
