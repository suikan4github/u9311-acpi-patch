function patch-ubuntu() {
    echo "For Ubuntu."

    # Working directory for the patching process.
    SRC=$(pwd)/acpi_temp

    CPIO_SRC=$(pwd)/kernel/firmware/acpi/

    mkdir -p $SRC
    cd $SRC
    sudo cat /sys/firmware/acpi/tables/SSDT4 > SSDT4.aml

    sudo apt update && sudo apt install acpica-tools patch

    # Disassemble the ACPI table to a human-readable format.
    iasl -d SSDT4.aml

    # Create a patch file to modify the ACPI table.
    cat <<- EOF | tee fujitsu-vdd.patch
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

    # Apply the patch to the disassembled ACPI table.
    patch < fujitsu-vdd.patch

    # If fail, exit the shell function.
    if [ $? -ne 0 ]; then
        echo "Failed to apply the patch. Exiting."
        return 1
    fi

    # Reassemble the patched ACPI table back to binary format.
    iasl -sa SSDT4.dsl 

    # Create a working directory.
    mkdir -p ${CPIO_SRC}

    # Copy patched aml file to the working directory. 
    # The directory structure must be `kernel/firmware/acpi/`
    cp ${SRC}/SSDT4.aml ${CPIO_SRC}

    # Generate CPIO archive 
    cd ${SRC}
    find kernel | cpio -H newc -o > ./acpi_override.cpio

    # Deploy the CPIO file.
    sudo cp ./acpi_override.cpio /boot/acpi_override.cpio

    # Add ACPI patch CPIO file to the initrd.  
    ADDITIONAL_INITRD='GRUB_EARLY_INITRD_LINUX_CUSTOM="acpi_override.cpio"'
    # Is additional line already present in /etc/default/grub? If not, append it.
    if ! grep -qF "$ADDITIONAL_INITRD" /etc/default/grub; then
        echo "$ADDITIONAL_INITRD" | sudo tee -a /etc/default/grub
    fi

    # Update GRUB configuration to include the new initrd.
    sudo update-grub

    return 0
}
