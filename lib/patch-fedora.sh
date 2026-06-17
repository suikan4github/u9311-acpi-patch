# shell function to patch the ACPI tables on a Fujitsu U9311 laptop to fix the VDD issue.
# This function must work on both Fedora Workstation and Fedora Atomic desktop system. 
function patch-fedora() {
    echo "For Fedora Workstation."

    # Working directory for the patching process.
    SRC=$(pwd)/acpi_temp

    # Destination directory for the patched ACPI tables.
    DST=/usr/local/etc/acpi-overrides

    # Create a temporary directory to store the ACPI tables and the patch.
    mkdir -p ${SRC}
    cd ${SRC}
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

    CONTAINER=patch-container

    # Create a temporary container to apply the patch.
    echo "Creating temporary container ${CONTAINER}..."
    toolbox create -c ${CONTAINER} -y

    # Update DNF cache inside the container.
    toolbox run -c ${CONTAINER} -- sudo dnf makecache

    # Install package inside container to handle the ACPI tables.
    echo "Installing acpica-tools and patch inside container ${CONTAINER}..."
    toolbox run -c ${CONTAINER} -- sudo dnf install -y acpica-tools patch

    # Disassemble the ACPI table to a human-readable format, inside container.
    echo "Disassembling the ACPI table inside container ${CONTAINER}..."
    toolbox run -c ${CONTAINER} -- iasl -d SSDT4.aml

    # Apply the patch to the disassembled ACPI table, inside container.
    echo "Applying the patch inside container ${CONTAINER}..."
    toolbox run -c ${CONTAINER} -- patch < fujitsu-vdd.patch

    # If patch fail, exit the shell function.
    if [ $? -ne 0 ]; then
        echo "Failed to apply the patch. Remove the temporaly container and exit."
        # Remove the temporary container before exiting.
        toolbox rm ${CONTAINER} -y
        return 1
    fi

    # Reassemble the patched ACPI table back to binary format, inside container.
    echo "Reassembling the patched ACPI table inside container ${CONTAINER}..."
    toolbox run -c ${CONTAINER} -- iasl -sa SSDT4.dsl

    # Remove the temporary container after patching.
    echo "Removing temporary container ${CONTAINER}..."
    toolbox rm ${CONTAINER} -y

    # Copy the patched ACPI table to the destination directory.
    if [ -d /run/ostree-booted ]; then
        # Fedora Atomic Desktop (Kinoite, Silverblue, etc.) 用の処理
        DST=/etc/acpi-overrides
    else
        # Fedora Workstation / Spin 用の処理
        DST=/usr/local/etc/acpi-overrides
    fi
    echo "Copying the patched ACPI table to ${DST}..."
    sudo mkdir -p ${DST}
sudo cp ${SRC}/SSDT4.aml ${DST}


    # Deploy the patched ACPI table by creating a dracut configuration file to load the patched table at boot time.
    echo "Creating dracut configuration file /etc/dracut.conf.d/99-acpi-override.conf..."
    cat <<-EOF | sudo tee /etc/dracut.conf.d/99-acpi-override.conf
    acpi_override="yes"
    acpi_table_dir="${DST}"
EOF

    # Regenerate the initramfs to include the patched ACPI table.
    echo "Regenerating the initramfs to include the patched ACPI table..."
    if [ -d /run/ostree-booted ]; then
        # Fedora Atomic Desktop (Kinoite, Silverblue, etc.) 用の処理
        sudo rpm-ostree initramfs --enable

        # In the case of error, re-enable the initramfs to regenerate it.
        if [ $? -ne 0 ]; then
            echo "Failed to generate the initramfs. Re-enabling it."
            sudo rpm-ostree initramfs --disable
            sudo rpm-ostree initramfs --enable
        fi

    else
        # Fedora Workstation / Spin 用の処理
        sudo dracut --force --verbose
    fi

    echo "ACPI patch applied successfully. Please reboot your system for the changes to take effect."
    return 0
}