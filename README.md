# StackedOllama iOS

[![iOS CI/CD](https://github.com/YOUR_USERNAME/StackedOllama-iOS/actions/workflows/ios.yml/badge.svg)](https://github.com/YOUR_USERNAME/StackedOllama-iOS/actions/workflows/ios.yml)
[![Swift Tests](https://github.com/YOUR_USERNAME/StackedOllama-iOS/actions/workflows/swift-tests.yml/badge.svg)](https://github.com/YOUR_USERNAME/StackedOllama-iOS/actions/workflows/swift-tests.yml)
[![codecov](https://codecov.io/gh/YOUR_USERNAME/StackedOllama-iOS/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_USERNAME/StackedOllama-iOS)

Premium iOS app for autonomous AI agents with voice interaction.

## Features

- 🤖 4 AI agents (Nova, Julie, Stheno, Dolphin)
- 🎤 Voice input/output
- ✨ Glassmorphism UI
- 🔄 Swipe between agents
- 🌐 Remote access via Cloudflare

## Quick Start

```bash
# Install dependencies
bundle install

# Health check
bundle exec fastlane ios health_check

# Dry run (test locally)
DISABLE_SLACK=true SKIP_ARCHIVE=true bundle exec fastlane ios dry_run

# Push to trigger CI
git push origin main
```

## CI/CD Pipeline

- ✅ Automatic build on push
- ✅ AI-generated changelog (local Ollama)
- ✅ TestFlight upload (internal/external)
- ✅ App Store release (on tag)
- ✅ Slack notifications
- ✅ Code coverage (Codecov)

## Release

```bash
git tag v1.0.0
git push --tags
```

## Documentation

- [Quick Start Guide](QUICK_START.md)
- [Dry Run Testing](DRY_RUN_GUIDE.md)
- [AI Changelog](AI_CHANGELOG_GUIDE.md)
- [Advanced Features](ADVANCED_FEATURES.md)
