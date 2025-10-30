# Repository Structure

This document describes the directory organization of the volumio-adaptive-themes repository.

## Root Level

```
volumio-adaptive-themes/
  README.md                 - Project overview, both themes, configuration hierarchy
  LICENSE                   - GPL v2 license
  .gitignore               - Files to exclude from repository
  AUTHORS                  - Project contributors
  STRUCTURE.md             - This file
  
  volumio-plymouth-adaptive/   - Plymouth boot splash theme
  volumio-text-adaptive/       - Text-based UI theme (planned)
  docs/                        - Shared documentation
  .github/                     - GitHub templates and workflows
```

## volumio-plymouth-adaptive/

```
volumio-plymouth-adaptive/
  README.md                    - Theme overview and features
  INSTALLATION.md              - Step-by-step installation guide
  QUICK_REFERENCE.md           - Command reference and troubleshooting
  volumio-adaptive.script      - Main Plymouth script (8.4 KB)
  volumio-adaptive.plymouth    - Theme configuration (296 bytes)
  generate-rotated-sequences.sh - Image generation script (4.1 KB)
  
  examples/
    cmdline-examples.txt       - Example kernel command lines
  
  docs/
    TROUBLESHOOTING.md         - Common issues and solutions
    TECHNICAL.md               - Technical implementation details
  
  sequence0/                   - NOT IN REPO (generated locally)
  sequence90/                  - NOT IN REPO (generated locally)
  sequence180/                 - NOT IN REPO (generated locally)
  sequence270/                 - NOT IN REPO (generated locally)
```

## volumio-text-adaptive/

```
volumio-text-adaptive/
  README.md                    - Theme overview (placeholder)
  [Future files when specifications provided]
```

## docs/

```
docs/
  ROTATION_MATH.md             - Explanation of rotation calculations
  RASPBERRY_PI_SETUP.md        - Pi-specific configuration guide
  CONTRIBUTING.md              - Contribution guidelines
```

## .github/

```
.github/
  ISSUE_TEMPLATE.md            - Template for bug reports
  PULL_REQUEST_TEMPLATE.md     - Template for pull requests
```

## Key Design Decisions

### Image Sequences Excluded

The sequence0/, sequence90/, sequence180/, and sequence270/ directories contain:
- 97 PNG files each (388 files total)
- Approximately 50-100 MB total size
- Too large for git repository

Users generate these locally using generate-rotated-sequences.sh.

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

### Separation of Concerns

Each theme type has its own directory:
- Self-contained with own README
- Own installation guide
- Own documentation
- Shared docs only in root docs/ directory

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

As the project grows:
- Additional theme directories follow same pattern
- Shared utilities go in root-level utils/ directory
- Architecture documentation goes in docs/
- More specific examples go in theme-specific examples/ directories

## Maintenance

This file should be updated when:
- New directories are added
- File organization changes
- New theme types are added
- Major restructuring occurs
