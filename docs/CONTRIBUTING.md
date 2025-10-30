# Contributing to Volumio Adaptive Themes

Thank you for your interest in contributing to this project.

## Important Context

This repository contains two themes with different rotation approaches:

**volumio-adaptive** (Image-based):
- Uses `plymouth=` parameter for theme-level rotation
- Pre-rotated image sequences
- Runtime detection patches theme script
- Suitable for animated graphical themes

**volumio-text** (Text-based):
- Uses framebuffer rotation (`video=` or `fbcon=` parameters)
- No runtime detection needed
- Simplified script (no coordinate transformation)
- Plymouth Script API cannot rotate text images

When contributing, be aware of which theme your changes apply to and use the appropriate rotation method.

## Code of Conduct

Be respectful, constructive, and professional in all interactions.

## How to Contribute

### Reporting Issues

Use the issue template provided in the repository. Include:
- Complete environment details (Pi model, OS, kernel, display)
- Configuration files (userconfig.txt, cmdline.txt)
- Logs and error messages
- Steps to reproduce

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on actual hardware
5. Update documentation if needed
6. Submit pull request using the PR template

### Code Style Guidelines

**Critical Requirements**:
- NO emojis or emoticons
- NO unicode icons or bullets  
- NO em dashes (use hyphen-minus "-")
- NO smart quotes or ellipses
- NO non-ASCII characters
- Use ONLY 7-bit printable ASCII (characters 32-126)

**Script Files**:
- Follow existing Plymouth script conventions
- Comment complex logic clearly
- Maintain compatibility with Plymouth 0.9.x

**Documentation**:
- Use plain markdown (.md)
- ASCII characters only
- Clear, concise language
- Include examples where helpful

**Shell Scripts**:
- POSIX-compliant when possible
- Comment non-obvious operations
- Handle errors explicitly
- Test on target hardware

### Testing Requirements

All contributions must be tested on actual hardware:
- Minimum: Raspberry Pi 3 or newer
- Test all rotation angles (0, 90, 180, 270)
- Verify smooth animation (for image-based themes)
- Check memory usage reasonable
- Confirm rotation works correctly

**For volumio-adaptive contributions**:
- Test with `plymouth=` parameter
- Verify runtime detection works (if installed)
- Confirm no initramfs rebuild needed for rotation changes
- Test both boot and shutdown

**For volumio-text contributions**:
- Test with `video=...,rotate=` or `fbcon=rotate:` parameters
- Verify text appears correctly oriented
- Confirm framebuffer rotation is working
- No runtime detection testing needed

### Documentation Updates

When changing functionality:
- Update relevant README files
- Update INSTALLATION.md if process changes
- Update QUICK_REFERENCE.md if commands change
- Add entry to change log in root README.md

### Commit Messages

Use clear, descriptive commit messages:
- First line: Brief summary (50 chars or less)
- Blank line
- Detailed explanation if needed
- Reference issue numbers where applicable

Example:
```
Fix rotation detection for portrait displays

ParsePlymouthRotation was not handling edge case where
plymouth= parameter appears at end of command line without
trailing space. Added bounds checking.

Fixes #42
```

### Adding New Features

Before starting work on major features:
1. Open an issue to discuss the feature
2. Wait for maintainer feedback
3. Ensure it aligns with project goals
4. Get approval before significant work

### Adding New Themes

New theme types (beyond plymouth and text):
1. Discuss in issue first
2. Follow directory structure pattern
3. Provide complete documentation
4. Include installation guide
5. Test thoroughly

### File Organization

Place new files in appropriate directories:
- Plymouth themes: volumio-plymouth-adaptive/
- Text themes: volumio-text-adaptive/
- Shared documentation: docs/
- GitHub templates: .github/

**Integration Note**: In volumio-os, volumio-text-adaptive becomes `volumio-text` and uses framebuffer rotation. When contributing to volumio-os integration, be aware of this difference.

### Licensing

All contributions must be compatible with GPL v2.

By submitting a pull request, you agree that your contribution will be licensed under GPL v2.

### Questions

If you have questions:
1. Check existing documentation first
2. Search closed issues
3. Open new issue with [Question] tag

## Maintainer Guidelines

For project maintainers:

### Reviewing Pull Requests

- Verify testing was performed
- Check code style compliance
- Ensure documentation updated
- Test on hardware if possible
- Provide constructive feedback

### Merging

- Squash commits if appropriate
- Update change log in README.md
- Tag releases appropriately
- Thank contributors

### Release Process

1. Update version numbers
2. Update change log
3. Create git tag
4. Write release notes
5. Announce in appropriate channels

## Recognition

Contributors will be:
- Added to AUTHORS file
- Credited in release notes
- Thanked publicly

Thank you for contributing to Volumio Adaptive Themes.
