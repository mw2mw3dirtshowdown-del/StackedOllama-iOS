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

## Configuration

### Service URLs

The app connects to remote services. Configure URLs in `StackedOllama/Info.plist`:

| Key | Default | Description |
|-----|---------|-------------|
| `LLM_BASE_URL` | `https://assessments-exclusive-rap-circulation.trycloudflare.com` | Remote Ollama API for chat/streaming |
| `TTS_BASE_URL` | `http://192.168.1.198:5556` | Local TTS server for speech synthesis |
| `AUTONOMOUS_BASE_URL` | `https://assessments-exclusive-rap-circulation.trycloudflare.com` | Remote autonomous agent API |
| `LLM_FALLBACK_URL` | `http://192.168.1.198:5555` | Local fallback for LLM if remote fails |
| `AUTONOMOUS_FALLBACK_URL` | `http://192.168.1.198:5557` | Local fallback for autonomous agents |

### CI/CD Secrets

For GitHub Actions and Xcode Cloud, set these secrets:

| Secret | Description |
|--------|-------------|
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect API key issuer ID |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | App Store Connect API private key |
| `MATCH_PASSWORD` | Match repo password for code signing |
| `GH_TOKEN` | GitHub personal access token for releases |
| `SLACK_WEBHOOK_URL` | Slack webhook for build notifications |
| `CODECOV_TOKEN` | Codecov token for coverage reports |

### Development vs Production

Use `Config/dev.xcconfig` for development (local URLs), `Config/prod.xcconfig` for production (remote URLs).

To override in Xcode:
1. Open `StackedOllama.xcodeproj`
2. Select target > Build Settings
3. Search for "xcconfig"
4. Set "Config File" to desired .xcconfig file

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
