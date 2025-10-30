Installation Guide - Volumio Text Adaptive Theme
=================================================

REQUIREMENTS
------------

- Volumio 3.x installation
- Root/sudo access
- Plymouth package installed (included in Volumio)

INSTALLATION STEPS
------------------

1. Download Theme Files
   
   Transfer volumio-text directory to your Volumio device.
   
   Example using SCP:
   scp -r volumio-text volumio@volumio.local:/home/volumio/

2. Install Theme
   
   SSH into Volumio:
   ssh volumio@volumio.local
   
   Copy theme to Plymouth directory:
   sudo cp -r /home/volumio/volumio-text /usr/share/plymouth/themes/
   
   Verify files:
   ls -la /usr/share/plymouth/themes/volumio-text
   
   Should show:
   - volumio-text.script
   - volumio-text.plymouth

3. Set as Default Theme
   
   sudo plymouth-set-default-theme volumio-text
   
   Verify theme is set:
   sudo plymouth-set-default-theme --list
   
   Current theme marked with asterisk.

4. Update Initramfs
   
   sudo update-initramfs -u
   
   Wait for completion (may take 1-2 minutes).

5. Configure Boot Parameters
   
   Edit /boot/cmdline.txt:
   ```
   sudo nano /boot/cmdline.txt
   ```
   
   Verify single line contains required Plymouth parameters:
   - quiet (suppress verbose kernel messages)
   - splash (enable Plymouth)
   - logo.nologo (hide Raspberry Pi logo)
   
   Add rotation if needed:
   - rotate=90, rotate=180, or rotate=270
   
   **Example cmdline.txt** (append rotation at end):
   ```
   splash plymouth.ignore-serial-consoles dwc_otg.fiq_enable=1 dwc_otg.fiq_fsm_enable=1 dwc_otg.fiq_fsm_mask=0xF dwc_otg.nak_holdoff=1 quiet console=serial0,115200 console=tty1 imgpart=UUID=cfdb2ece-53a1-41e1-976e-083b99a3d665 imgfile=/volumio_current.sqsh bootpart=UUID=3533-4CB0 datapart=UUID=f76792a9-df7b-4cdd-8b61-c2c89d5cbb6e uuidconfig=cmdline.txt pcie_aspm=off pci=pcie_bus_safe rootwait bootdelay=7 logo.nologo vt.global_cursor_default=0 net.ifnames=0 snd-bcm2835.enable_compat_alsa= snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_headphones=1 loglevel=0 nodebug use_kmsg=no rotate=90
   ```
   
   **Important:** Do not modify existing parameters. Only add rotation at the end.

6. Reboot
   
   sudo reboot
   
   Theme will display during boot.

ROTATION CONFIGURATION
----------------------

If your display is physically rotated, configure both:

1. Console rotation (in /boot/cmdline.txt):
   rotate=90
   
2. Plymouth image selection (if using image theme):
   plymouth=volumio-adaptive-90.png

For text theme:
- Only rotate= parameter needed
- Theme automatically adapts layout
- No plymouth= parameter required

TESTING WITHOUT REBOOT
-----------------------

Test theme before rebooting:

1. Start Plymouth daemon:
   sudo plymouthd --debug --debug-file=/tmp/plymouth.log

2. Show splash:
   sudo plymouth show-splash

3. Send test message:
   sudo plymouth message --text="Testing Volumio Text Theme"

4. Stop Plymouth:
   sudo plymouth quit

5. Check debug log:
   cat /tmp/plymouth.log

VERIFICATION
------------

After installation, verify:

1. Theme files exist:
   ls /usr/share/plymouth/themes/volumio-text/

2. Theme is active:
   sudo plymouth-set-default-theme
   
   Should output: volumio-text

3. Initramfs updated:
   ls -l /boot/initrd.img*
   
   Check modification date is recent.

4. Boot parameters correct:
   cat /boot/cmdline.txt
   
   Verify quiet splash present.

SWITCHING THEMES
----------------

To switch between themes:

List available themes:
sudo plymouth-set-default-theme --list

Set different theme:
sudo plymouth-set-default-theme <theme-name>

Update initramfs:
sudo update-initramfs -u

Reboot:
sudo reboot

UNINSTALLATION
--------------

To remove theme:

1. Switch to different theme:
   sudo plymouth-set-default-theme <other-theme>

2. Update initramfs:
   sudo update-initramfs -u

3. Remove theme files:
   sudo rm -rf /usr/share/plymouth/themes/volumio-text

TROUBLESHOOTING
---------------

Theme not appearing during boot:

Check 1: Plymouth installed
dpkg -l | grep plymouth

Install if missing:
sudo apt-get update
sudo apt-get install plymouth plymouth-themes

Check 2: Theme files exist
ls -la /usr/share/plymouth/themes/volumio-text

Check 3: Theme is set
sudo plymouth-set-default-theme

Check 4: Initramfs updated
ls -l /boot/initrd.img*

Check 5: Boot parameters
cat /boot/cmdline.txt

Must contain: quiet splash

Check 6: Plymouth running
ps aux | grep plymouthd

Text rotated incorrectly:

- Verify rotate= parameter in /boot/cmdline.txt
- Check physical display orientation
- Ensure rotate= matches physical rotation
- Remember: 0=normal, 90=right, 180=upside, 270=left

Text not centered:

- Theme auto-centers based on detected dimensions
- Check /proc/cmdline for correct rotate= value
- Test with plymouth --debug mode

System messages not showing:

- Messages come from init system
- Ensure quiet parameter in cmdline.txt (not noquiet)
- Check systemd service status

ADVANCED: DEBUG MODE
--------------------

Enable Plymouth debug logging:

1. Add to /boot/cmdline.txt:
   plymouth.debug

2. Reboot

3. After boot, check log:
   cat /var/log/plymouth-debug.log

4. Review for errors or warnings

COMMON CMDLINE.TXT EXAMPLES
----------------------------

**Note:** Actual cmdline.txt varies per installation (UUIDs differ).
These examples show typical Volumio format with relevant parameters.

**Standard (no rotation):**
```
splash plymouth.ignore-serial-consoles dwc_otg.fiq_enable=1 dwc_otg.fiq_fsm_enable=1 dwc_otg.fiq_fsm_mask=0xF dwc_otg.nak_holdoff=1 quiet console=serial0,115200 console=tty1 imgpart=UUID=cfdb2ece-53a1-41e1-976e-083b99a3d665 imgfile=/volumio_current.sqsh bootpart=UUID=3533-4CB0 datapart=UUID=f76792a9-df7b-4cdd-8b61-c2c89d5cbb6e uuidconfig=cmdline.txt pcie_aspm=off pci=pcie_bus_safe rootwait bootdelay=7 logo.nologo vt.global_cursor_default=0 net.ifnames=0 snd-bcm2835.enable_compat_alsa= snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_headphones=1 loglevel=0 nodebug use_kmsg=no
```

**With 90-degree rotation** (add at end):
```
splash plymouth.ignore-serial-consoles dwc_otg.fiq_enable=1 dwc_otg.fiq_fsm_enable=1 dwc_otg.fiq_fsm_mask=0xF dwc_otg.nak_holdoff=1 quiet console=serial0,115200 console=tty1 imgpart=UUID=cfdb2ece-53a1-41e1-976e-083b99a3d665 imgfile=/volumio_current.sqsh bootpart=UUID=3533-4CB0 datapart=UUID=f76792a9-df7b-4cdd-8b61-c2c89d5cbb6e uuidconfig=cmdline.txt pcie_aspm=off pci=pcie_bus_safe rootwait bootdelay=7 logo.nologo vt.global_cursor_default=0 net.ifnames=0 snd-bcm2835.enable_compat_alsa= snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_headphones=1 loglevel=0 nodebug use_kmsg=no rotate=90
```

**With debug enabled** (add at end):
```
splash plymouth.ignore-serial-consoles dwc_otg.fiq_enable=1 dwc_otg.fiq_fsm_enable=1 dwc_otg.fiq_fsm_mask=0xF dwc_otg.nak_holdoff=1 quiet console=serial0,115200 console=tty1 imgpart=UUID=cfdb2ece-53a1-41e1-976e-083b99a3d665 imgfile=/volumio_current.sqsh bootpart=UUID=3533-4CB0 datapart=UUID=f76792a9-df7b-4cdd-8b61-c2c89d5cbb6e uuidconfig=cmdline.txt pcie_aspm=off pci=pcie_bus_safe rootwait bootdelay=7 logo.nologo vt.global_cursor_default=0 net.ifnames=0 snd-bcm2835.enable_compat_alsa= snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_headphones=1 loglevel=0 nodebug use_kmsg=no plymouth.debug
```

**With specific display configuration:**
```
splash plymouth.ignore-serial-consoles dwc_otg.fiq_enable=1 dwc_otg.fiq_fsm_enable=1 dwc_otg.fiq_fsm_mask=0xF dwc_otg.nak_holdoff=1 quiet console=serial0,115200 console=tty1 imgpart=UUID=cfdb2ece-53a1-41e1-976e-083b99a3d665 imgfile=/volumio_current.sqsh bootpart=UUID=3533-4CB0 datapart=UUID=f76792a9-df7b-4cdd-8b61-c2c89d5cbb6e uuidconfig=cmdline.txt pcie_aspm=off pci=pcie_bus_safe rootwait bootdelay=7 logo.nologo vt.global_cursor_default=0 net.ifnames=0 snd-bcm2835.enable_compat_alsa= snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_headphones=1 loglevel=0 nodebug use_kmsg=no video=HDMI-A-1:800x480M@60,rotate=270
```

IMPORTANT NOTES
---------------

- cmdline.txt MUST be single line (no line breaks)
- Always backup cmdline.txt before editing
- Invalid cmdline.txt can prevent boot
- Keep backup SD card for recovery
- Test rotation values before permanent deployment

FILE PERMISSIONS
----------------

Correct permissions after installation:

sudo chown -R root:root /usr/share/plymouth/themes/volumio-text
sudo chmod 755 /usr/share/plymouth/themes/volumio-text
sudo chmod 644 /usr/share/plymouth/themes/volumio-text/*

INTEGRATION WITH VOLUMIO
-------------------------

This theme integrates with Volumio's boot sequence:

1. Kernel loads with cmdline.txt parameters
2. Plymouth starts early in boot
3. Theme displays "Volumio Player" title
4. System messages shown as services start
5. Plymouth exits when GUI ready
6. Volumio UI takes over display

SUPPORT
-------

For installation issues:
https://github.com/foonerd/volumio-adaptive-themes/issues

Volumio forum:
https://community.volumio.com/
