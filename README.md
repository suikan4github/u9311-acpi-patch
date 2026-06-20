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
| Fedora KDE Plasma | 43        |  OK    |
| Fedora KDE Plasma | 44        |  OK    |
| Fedora Kinoite    | 44        |  OK    |
| Ubuntu            | 25.10     |  OK    |
| Ubuntu            | 26.04 LTS |  OK    |

Hardware : 
- Fujitsu LIFEBOOK U9311FX Intel Core i5 1135G7.

## Usage
Run the following command to apply the ACPI patch:
```sh
./u9311-acpi-patch.sh
```
If the ACPI table has mismatch with the patch, script will terminate the process and exit with error. In this case, system will be untouched. 

Reboot the system after running the script to apply the patch.

## Confirm the patch is applied
After rebooting, run the following command to check the kernel log for the message indicating that the ACPI patch has been applied:

```sh
journalctl -k | grep -i "Table Upgrade"
```
You will see the following message in the log if the patch is applied successfully.

```
Feb 27 15:51:28 fedora kernel: ACPI: Table Upgrade: override [SSDT-INTEL -IgfxSsdt]
```

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
    # Ubuntu: remove the GRUB configuration
    echo "[Ubuntu] Removing ACPI patch from GRUB configuration..."
    TARGET='GRUB_EARLY_INITRD_LINUX_CUSTOM="acpi_override.cpio"'
    sudo cp /etc/default/grub /etc/default/grub.bak && \
    awk -v TARGET="$TARGET" '$0 != TARGET' /etc/default/grub.bak |\
        sudo tee /etc/default/grub
    # Update GRUB configuration
    sudo update-grub
elif [ "$ID" = "fedora" ] || [ "$ID_LIKE" = "*fedora*" ]; then
    # Fedora: remove the dracut config
    sudo mv /etc/dracut.conf.d/99-acpi-override.conf\
         /etc/dracut.conf.d/99-acpi-override.conf.bak
    if [ -e /run/ostree-booted ]; then
        # Fedora Workstation / Spin 
        echo "[fedora] Detected Fedora Atomic Desktop."
        echo "[fedora] Rebuilding initramfs..."
        sudo rpm-ostree initramfs --disable
        sudo rpm-ostree initramfs --enable
    else
        # Fedora Workstation / Spin 
        echo "[fedora] Detected Fedora Workstation / Spin."
        echo "[fedora] Rebuilding initramfs..."
        sudo dracut --force --verbose
    fi

else
    echo "Unsupported distro: $ID" >&2
    exit 1
fi

```
Above commands will remove the configuration to read the ACPI Patch. After rebooting, system will be back to the original state without ACPI patch.

Tested on :
- Fedora 44 KDE Plasma
- Kubuntu 26.04 LTS


## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
