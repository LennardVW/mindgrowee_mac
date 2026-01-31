# Makefile for MindGrowee macOS app

.PHONY: build test run clean bundle install

# Default target
all: build

# Build the project
build:
	swift build

# Run tests
test:
	swift test

# Build and run
run: build
	.build/debug/mindgrowee_mac

# Clean build artifacts
clean:
	swift package clean
	rm -rf .build
	rm -rf MindGrowee.app

# Create app bundle
bundle:
	./scripts/build.sh --bundle

# Install locally (creates app bundle in /Applications)
install: bundle
	cp -R MindGrowee.app /Applications/
	@echo "✅ Installed to /Applications/MindGrowee.app"

# Format code (requires swift-format)
format:
	@if command -v swift-format >/dev/null 2>&1; then \
		swift-format format --recursive --in-place Sources/ Tests/; \
	else \
		echo "⚠️  swift-format not installed. Install with: brew install swift-format"; \
	fi

# Lint code (requires swift-format)
lint:
	@if command -v swift-format >/dev/null 2>&1; then \
		swift-format lint --recursive Sources/ Tests/; \
	else \
		echo "⚠️  swift-format not installed. Install with: brew install swift-format"; \
	fi

# Show help
help:
	@echo "Available targets:"
	@echo "  make build    - Build the project"
	@echo "  make test     - Run tests"
	@echo "  make run      - Build and run the app"
	@echo "  make clean    - Clean build artifacts"
	@echo "  make bundle   - Create .app bundle"
	@echo "  make install  - Install to /Applications"
	@echo "  make format   - Format code (requires swift-format)"
	@echo "  make lint     - Lint code (requires swift-format)"
	@echo "  make help     - Show this help"
