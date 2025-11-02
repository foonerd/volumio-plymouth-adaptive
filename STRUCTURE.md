# Repository Structure

This document describes the directory organization of the volumio-adaptive-themes repository.

## Root Level

```
volumio-adaptive-themes/
  README.md                     - Project overview, both themes, configuration hierarchy
  LICENSE                       - GPL v2 license
  .gitignore                    - Files to exclude from repository
  AUTHORS                       - Project contributors
  STRUCTURE.md                  - This file
  
  volumio-plymouth-adaptive/    - Plymouth boot splash theme
  volumio-text-adaptive/        - Text-based Plymouth theme
  docs/                         - Shared documentation
  .github/                      - GitHub templates and workflows
```

## volumio-plymouth-adaptive/

```
volumio-plymouth-adaptive/
  README.md                     - Theme overview and features
  INSTALLATION.md               - Step-by-step installation guide
  QUICK_REFERENCE.md            - Command reference and troubleshooting
  volumio-adaptive.script       - Main Plymouth script (8.7 KB)
  volumio-adaptive.plymouth     - Theme configuration (296 bytes)
  generate-rotated-sequences.sh - Animation sequence generation script (4.1 KB)
  generate-overlays.sh          - Message overlay generation script (6.8 KB) [NEW v1.02]
  
  runtime-detection/
    00-plymouth-rotation        - Init-premount script for boot detection
    plymouth-rotation.service   - Systemd service for shutdown detection
    plymouth-rotation.sh        - Runtime detection script
    INSTALL.md                  - Installation guide for runtime detection
  
  examples/
    cmdline-examples.txt        - Example kernel command lines
  
  docs/
    TROUBLESHOOTING.md          - Common issues and solutions
    TECHNICAL.md                - Technical implementation details
  
  sequence0/                    - NOT IN REPO (generated locally, contains animations + overlays)
  sequence90/                   - NOT IN REPO (generated locally, contains animations + overlays)
  sequence180/                  - NOT IN REPO (generated locally, contains animations + overlays)
  sequence270/                  - NOT IN REPO (generated locally, contains animations + overlays)
```

## volumio-text-adaptive/

**INTEGRATION NOTE**: In volumio-os integration, this theme becomes `volumio-text` and replaces the existing volumio-text theme. The directory name remains `volumio-text-adaptive` in this development repository for clarity.

```
volumio-text-adaptive/
  README.md                     - Theme overview and features
  INSTALLATION.md               - Step-by-step installation guide
  TECHNICAL.md                  - Technical implementation details
  volumio-text.script           - Main theme script (6.3 KB)
  volumio-text.plymouth         - Theme configuration (250 bytes)
```

## docs/

```
docs/
  ROTATION_MATH.md              - Explanation of rotation calculations
  RASPBERRY_PI_SETUP.md         - Pi-specific configuration guide
  CONTRIBUTING.md               - Contribution guidelines
```

## .github/

```
.github/
  ISSUE_TEMPLATE.md             - Template for bug reports
  PULL_REQUEST_TEMPLATE.md      - Template for pull requests
```

## Key Design Decisions

### Image Sequences Excluded

The sequence0/, sequence90/, sequence180/, and sequence270/ directories contain:
- 123 PNG files each (492 files total) - v1.02
  - 97 animation files (progress-*.png, micro-*.png, layout-constraint.png)
  - 26 overlay files (overlay-*.png, overlay-*-compact.png)
- Approximately 60-120 MB total size
- Too large for git repository

Users generate these locally:
- Animations: generate-rotated-sequences.sh
- Overlays: generate-overlays.sh (NEW v1.02)

### Documentation Format

All documentation uses Markdown (.md) format with:
- Plain ASCII characters only (no emojis, unicode bullets)
- Hyphen-minus "-" instead of em dashes
- Standard ASCII quotes (no smart quotes)
- Accessibility-focused formatting

### Configuration Files

Examples of configuration files show:
- Volumio-specific hierarchy (/boot/userconfig.txt, /boot/cmdline.txt)
- Proper parameter placement
- Real-world working configurations

Note: cmdline.txt location varies by OS:
- Volumio 3.x/4.x: /boot/cmdline.txt
- Raspberry Pi OS Bookworm: /boot/firmware/cmdline.txt
- Runtime detection scripts handle both locations automatically

### Separation of Concerns

Each theme type has its own directory:
- Self-contained with own README
- Own installation guide
- Own documentation
- Shared docs only in root docs/ directory

**Integration Note**: In volumio-os:
- volumio-adaptive is added as a new theme
- volumio-text-adaptive becomes volumio-text (replaces existing)
- Different rotation methods: volumio-adaptive uses `plymouth=`, volumio-text uses framebuffer rotation

### Runtime Detection Solution

The runtime-detection/ subdirectory contains:
- Init-premount script for early boot patching
- Systemd service for shutdown detection
- Separate installation guide

**IMPORTANT**: Runtime detection is for volumio-adaptive theme only.
- volumio-adaptive uses `plymouth=` parameter and requires runtime patching
- volumio-text uses framebuffer rotation (`video=` or `fbcon=`) and does NOT need runtime detection

Design rationale:
- Plymouth API limitations (GetParameter, GetKernelCommandLine return NULL)
- /proc/cmdline not accessible from Plymouth script in initramfs
- Plymouth Script API cannot rotate text images (no Image.Rotate() function)
- Two-phase solution for volumio-adaptive: boot (init-premount) + shutdown (systemd)
- Enables true rotation adaptation for volumio-adaptive without initramfs rebuild
- volumio-text relies on kernel framebuffer rotation (automatic)
- Critical for Volumio OTA update compatibility
- User copies files to system locations during installation

### GitHub Integration

Standard GitHub features:
- Issue templates for consistent bug reports
- PR templates for consistent contributions
- CONTRIBUTING.md for guidelines
- AUTHORS for recognition

## File Naming Conventions

- Markdown: .md extension
- Scripts: .sh extension
- Plymouth: .script and .plymouth extensions
- Documentation: UPPERCASE.md for important files
- Examples: lowercase with descriptive names

## Future Additions

Version 1.02 includes both core themes (plymouth-adaptive with overlay messaging, text-adaptive).

As the project grows:
- Additional theme variants may follow same pattern
- Shared utilities go in root-level utils/ directory
- Architecture documentation goes in docs/
- More specific examples go in theme-specific examples/ directories

## Maintenance

This file should be updated when:
- New directories are added
- File organization changes
- New theme types are added
- Major restructuring occurs
