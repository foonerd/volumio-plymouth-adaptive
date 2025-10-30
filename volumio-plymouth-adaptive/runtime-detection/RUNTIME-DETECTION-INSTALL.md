Runtime Detection Installation Guide
=====================================

OVERVIEW
--------

These files enable Plymouth theme to adapt to rotation changes without
requiring initramfs rebuild. This is critical for Volumio OTA updates.

COMPONENTS
----------

1. 00-plymouth-rotation
   - Init-premount script
   - Runs in early initramfs before Plymouth starts
   - Patches script at boot time

2. plymouth-rotation.service
   - Systemd service unit
   - Patches installed script for shutdown/reboot
   
3. plymouth-rotation.sh
   - Detection script called by service
   - Reads rotation from /proc/cmdline

INSTALLATION STEPS
------------------

Step 1: Install init-premount script
-------------------------------------

    sudo cp 00-plymouth-rotation /etc/initramfs-tools/scripts/init-premount/
    sudo chmod +x /etc/initramfs-tools/scripts/init-premount/00-plymouth-rotation

Step 2: Install systemd service
--------------------------------

    sudo cp plymouth-rotation.sh /usr/local/bin/
    sudo chmod +x /usr/local/bin/plymouth-rotation.sh
    
    sudo cp plymouth-rotation.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable plymouth-rotation.service

Step 3: Rebuild initramfs once
-------------------------------

    sudo update-initramfs -u

Step 4: Test
------------

    sudo reboot

VERIFICATION
------------

After reboot, both boot and shutdown should show correct rotation.

Test rotation changes:

1. Edit cmdline.txt (change plymouth= value)
   - Raspberry Pi OS: /boot/firmware/cmdline.txt
   - Volumio: /boot/cmdline.txt

2. Reboot (NO initramfs rebuild needed)

3. Verify both boot and shutdown show new rotation

SUPPORTED ROTATIONS
-------------------

- plymouth=0   (or omitted) - No rotation
- plymouth=90  - 90 degrees clockwise
- plymouth=180 - 180 degrees (upside-down)
- plymouth=270 - 270 degrees clockwise

TROUBLESHOOTING
---------------

Boot rotation wrong:
- Check init-premount script is executable
- Verify initramfs was rebuilt after installation
- Check /proc/cmdline contains plymouth= parameter

Shutdown rotation wrong:
- Check systemd service is enabled:
  systemctl status plymouth-rotation.service
- Verify script is executable:
  ls -la /usr/local/bin/plymouth-rotation.sh

Both directions wrong:
- Verify plymouth= parameter in cmdline.txt
- Check script has correct regex pattern

TECHNICAL DETAILS
-----------------

Why two components needed:

Boot phase:
- Plymouth runs from initramfs
- Must patch script IN initramfs
- init-premount runs before Plymouth

Shutdown/reboot phase:
- Plymouth runs from installed system
- Must patch script in /usr/share
- systemd service patches at boot for later shutdown

Both patches use same detection logic from /proc/cmdline.

UNINSTALLATION
--------------

Remove init-premount script:

    sudo rm /etc/initramfs-tools/scripts/init-premount/00-plymouth-rotation
    sudo update-initramfs -u

Remove systemd service:

    sudo systemctl disable plymouth-rotation.service
    sudo rm /etc/systemd/system/plymouth-rotation.service
    sudo rm /usr/local/bin/plymouth-rotation.sh
    sudo systemctl daemon-reload

COMPATIBILITY
-------------

Works on:
- Raspberry Pi OS Bookworm
- Volumio 3.x
- Volumio 4.x
- Any Debian-based system with initramfs-tools and systemd

Architecture:
- ARM (Raspberry Pi)
- amd64 (x86_64)
- All architectures supported by Plymouth

LIMITATIONS
-----------

- Requires reboot for rotation changes to take effect
- Does not detect rotation changes during runtime
- Community accepted: rotation changes naturally require reboot

This is intentional design - automatic detection adds complexity
without practical benefit.
