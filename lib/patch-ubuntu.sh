#!/bin/bash

# shell function to patch the ACPI tables on a Fujitsu U9311 laptop to fix the VDD issue.
# This function must work on both Fedora Workstation and Fedora Atomic desktop system. 
function patch-ubuntu() {
    echo "For Ubuntu."

    # Working directory for the patching process.
    SRC=$(pwd)/acpi_temp

    CPIO_SRC=$(pwd)/kernel/firmware/acpi/

    mkdir -p ${SRC}
    cd ${SRC} || exit 1
    # shellcheck disable=SC2024
    sudo cat /sys/firmware/acpi/tables/SSDT4 > SSDT4.aml


    # Create a patch file to modify the ACPI table.
    echo "Creating patch file fujitsu-vdd.patch..."
    cat <<-EOF | tee fujitsu-vdd.patch
	--- SSDT4.dsl.orig    2024-07-29 18:33:14.782373152 +0200
	+++ SSDT4.dsl 2024-07-29 18:38:33.021477685 +0200
	@@ -18,7 +18,7 @@
	  *     Compiler ID      "INTL"
	  *     Compiler Version 0x20160422 (538313762)
	  */
	-DefinitionBlock ("", "SSDT", 2, "INTEL ", "IgfxSsdt", 0x00003000)
	+DefinitionBlock ("", "SSDT", 2, "INTEL ", "IgfxSsdt", 0x00003001)  
	 {
	     External (_SB_.PC00, DeviceObj)
	     External (_SB_.PC00.GFX0, DeviceObj)
	@@ -115,11 +115,6 @@
	         {
	             If ((PDRD () == Zero))
	             {
	-                If ((VDDE == One))
	-                {
	-                    VDDE = Zero
	-                    Sleep (0x01F4)
	-                }
	             }
	 
	             NDID = 0x02
	@@ -2479,11 +2474,6 @@
	             {
	                 If ((PDRD () == Zero))
	                 {
	-                    If ((VDDE == One))
	-                    {
	-                        VDDE = Zero
	-                        Sleep (0x01F4)
	-                    }
	                 }
	             }
	EOF

    # Install required packages for patching.
    echo "Installing required packages for patching..."
    sudo apt update && sudo apt install acpica-tools patch

    # Disassemble the ACPI table to a human-readable format.
    echo "Disassembling the ACPI table..."
    iasl -d SSDT4.aml

    # Apply the patch to the disassembled ACPI table.
    echo "Applying the patch to the disassembled ACPI table..."
    patch < fujitsu-vdd.patch

    # If fail, exit the shell function.
    if [ $? -ne 0 ]; then
        echo "Failed to apply the patch. Exiting."
        return 1
    fi

    # Reassemble the patched ACPI table back to binary format.
    echo "Reassembling the patched ACPI table..."
    iasl -sa SSDT4.dsl 

    # Create a working directory.
    mkdir -p ${CPIO_SRC}

    # Copy patched aml file to the working directory. 
    # The directory structure must be `kernel/firmware/acpi/`
    echo "Copying the patched ACPI table to the working directory..."
    cp ${SRC}/SSDT4.aml ${CPIO_SRC}

    # Generate CPIO archive 
    echo "Generating CPIO archive..."
    cd ${SRC} || exit 1
    find kernel | cpio -H newc -o > ./acpi_override.cpio

    # Deploy the CPIO file.
    echo "Deploying the CPIO file to /boot/acpi_override.cpio..."
    sudo cp ./acpi_override.cpio /boot/acpi_override.cpio

    # Add ACPI patch CPIO file to the initrd.  
    ADDITIONAL_INITRD='GRUB_EARLY_INITRD_LINUX_CUSTOM="acpi_override.cpio"'
    # Is additional line already present in /etc/default/grub? If not, append it.
    if ! grep -qF "$ADDITIONAL_INITRD" /etc/default/grub; then
        echo "Adding ACPI patch CPIO file to the initrd in /etc/default/grub..."
        echo "$ADDITIONAL_INITRD" | sudo tee -a /etc/default/grub
    fi

    # Update GRUB configuration to include the new initrd.
    echo "Updating GRUB configuration..."
    sudo update-grub

    echo "ACPI patch applied successfully. Please reboot your system for the changes to take effect."
    return 0
}
