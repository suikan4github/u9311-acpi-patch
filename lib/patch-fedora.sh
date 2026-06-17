# shell function to patch the ACPI tables on a Fujitsu U9311 laptop to fix the VDD issue.
function patch-fedora() {
    echo "For Fedora Workstation."

    # Working directory for the patching process.
    SRC=$(pwd)/acpi_temp

    # Destination directory for the patched ACPI tables.
    DST=/usr/local/etc/acpi-overrides

    # Install package to handle the ACPI tables.
    sudo apt update && sudo apt install acpica-tools patch

    # Create a temporary directory to store the ACPI tables and the patch.
    mkdir -p $SRC
    cd $SRC
    sudo cat /sys/firmware/acpi/tables/SSDT4 > SSDT4.aml

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

    # Copy the patched ACPI table to the destination directory.
    sudo mkdir -p $DST
    sudo cp $SRC/SSDT4.aml $DST

    # Deploy the patched ACPI table by creating a dracut configuration file to load the patched table at boot time.
    cat <<-EOF | sudo tee /etc/dracut.conf.d/99-acpi-override.conf
    acpi_override="yes"
    acpi_table_dir="$DST"
EOF

    # Regenerate the initramfs to include the patched ACPI table.
    sudo dracut --force --verbose

    return 0
}