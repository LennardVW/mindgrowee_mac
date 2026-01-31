# Contributing to MindGrowee

Thank you for your interest in contributing to MindGrowee! This document provides guidelines for contributing.

## Development Setup

1. **Requirements**:
   - macOS 14.0+
   - Xcode 15.0+ or Swift 5.9+
   - Git

2. **Clone the repository**:
```bash
git clone https://github.com/LennardVW/mindgrowee_mac.git
cd mindgrowee_mac
```

3. **Build the project**:
```bash
swift build
```

4. **Run tests**:
```bash
swift test
```

## Branch Strategy

- `main`: Production-ready code
- `develop`: Integration branch for new features
- `feature/*`: Individual feature branches

**Workflow**:
1. Create a feature branch from `develop`
2. Make your changes
3. Write/update tests
4. Update documentation
5. Submit PR to `develop`

## Code Style

- Follow Swift API Design Guidelines
- Use meaningful variable names
- Add comments for complex logic
- Keep functions focused and small
- Use SwiftUI best practices

## Testing

- Write unit tests for new functionality
- Ensure all tests pass before submitting PR
- Test on macOS 14.0+ if possible

## Commit Messages

Use clear, descriptive commit messages:

```
Add feature X

- Detail 1
- Detail 2
```

## Pull Request Process

1. Update README.md if needed
2. Update CHANGELOG.md
3. Ensure CI passes
4. Request review
5. Address feedback
6. Merge to develop

## Reporting Issues

When reporting issues, please include:
- macOS version
- App version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable

## Feature Requests

We welcome feature requests! Please:
- Check if already requested
- Describe the use case
- Explain why it would be valuable

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
