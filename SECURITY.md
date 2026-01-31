# Security Policy

## Supported Versions

We currently provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of MindGrowee seriously. If you believe you've found a security vulnerability, please follow these steps:

### Do NOT

- **Do not** open a public issue on GitHub
- **Do not** discuss the vulnerability in public forums
- **Do not** exploit the vulnerability on any user's system

### DO

1. **Email us directly** at security@mindgrowee.app (or create a private security advisory on GitHub)
2. **Include the following information:**
   - Description of the vulnerability
   - Steps to reproduce (if applicable)
   - Potential impact
   - Suggested fix (if you have one)
   - Your contact information for follow-up

### What to Expect

1. **Acknowledgment** within 48 hours
2. **Initial assessment** within 1 week
3. **Regular updates** on our progress
4. **Credit** in the release notes (with your permission) once fixed

## Security Measures

MindGrowee implements the following security measures:

### Data Storage

- All data is stored locally on your device using SwiftData
- No data is transmitted to external servers
- No analytics or tracking
- No third-party SDKs with network access

### Privacy

- No account required
- No personal information collected
- Optional export/import for data portability

### Permissions

MindGrowee requests minimal permissions:
- Local notifications (optional)
- File system access (for import/export only)

## Known Limitations

- Data is not encrypted at rest (relies on macOS system encryption)
- No password protection for the app
- Backups are stored in plain JSON

## Best Practices for Users

1. Keep your Mac's system password secure
2. Enable FileVault for full disk encryption
3. Regularly export backups to secure locations
4. Keep the app updated to the latest version

## Security Updates

Security updates will be released as soon as possible after a vulnerability is confirmed. Users will be notified through:

1. GitHub releases
2. In-app update notifications (if implemented)
3. The release notes

## Contact

For security-related questions or to report vulnerabilities:

- **Email:** security@mindgrowee.app
- **Private Security Advisory:** Use GitHub's private vulnerability reporting
- **Response Time:** 48 hours for initial acknowledgment

Thank you for helping keep MindGrowee and its users safe!
