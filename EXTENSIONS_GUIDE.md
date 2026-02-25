# 🚀 Full-Stack Extensions Guide

## 🎯 What's New

This guide covers the **final layer** of automation:

1. ✅ **Changelog → GitHub Releases** (automatic)
2. ✅ **Crashlytics → Slack** (real-time alerts)
3. ✅ **Swift tests in Docker** (reproducible)

---

## 1️⃣ GitHub Releases (Automatic Changelog)

### How It Works

When you create a release tag:
```bash
fastlane ios release type:minor
```

**Automatic steps:**
1. ✅ Generate changelog from last 20 commits
2. ✅ Save to `CHANGELOG.md`
3. ✅ Commit changelog
4. ✅ Build & upload to App Store
5. ✅ Create GitHub Release with changelog
6. ✅ Notify Slack

### Manual Trigger
```bash
# Prepare changelog only
fastlane ios prepare_release

# Publish GitHub Release
fastlane ios publish_github_release
```

### Requirements
- GitHub CLI (`gh`) installed in Xcode Cloud
- `GH_TOKEN` secret in Xcode Cloud settings
- Token scope: `repo`

---

## 2️⃣ Crashlytics → Slack Notifications

### Setup

1. **Create Slack Webhook:**
   - https://api.slack.com/messaging/webhooks
   - Channel: `#crashlytics-alerts`
   - Copy webhook URL

2. **Add to Xcode Cloud:**
   ```
   App Store Connect → Xcode Cloud → Settings → Secrets
   Name: CRASHLYTICS_SLACK_WEBHOOK_URL
   Value: https://hooks.slack.com/services/...
   ```

3. **Done!** Automatic notifications on build success/failure

### Test Locally
```bash
export CRASHLYTICS_SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
fastlane ios notify_slack_crashlytics status:success
```

### Notification Format
```
🔥 Crashlytics SUCCESS – StackedOllama
Build: 42
Branch: master
Commit: abc123
```

---

## 3️⃣ Swift Tests in Docker

### Why Docker?

- ✅ **Reproducible** - Same environment every time
- ✅ **Fast** - Cached dependencies
- ✅ **Portable** - Run anywhere (local, CI, cloud)
- ✅ **Isolated** - No system conflicts

### Build & Run Locally

```bash
# Build image (first time only)
docker build -t stackedollama-tests .

# Run tests
docker run --rm stackedollama-tests

# Run with live code changes
docker run --rm -v $(pwd):/app stackedollama-tests
```

### CI Integration

**GitHub Actions** (`.github/workflows/swift-tests.yml`):
- Runs on every push/PR
- Builds Docker image
- Runs tests
- Uploads coverage to Codecov

### Test Coverage

```bash
# Generate coverage report
docker run --rm \
  -v $(pwd):/app \
  stackedollama-tests \
  swift test --enable-code-coverage

# View coverage
open .build/debug/codecov/index.html
```

---

## 🔥 Complete Workflow

### Development
```bash
# 1. Make changes
git add .
git commit -m "Add feature"
git push

# → GitHub Actions runs Docker tests
# → Xcode Cloud builds
# → Internal TestFlight
# → Slack: "✅ Build ready!"
```

### Release
```bash
# 1. Create release
fastlane ios release type:minor

# → Version bumped (1.0.0 → 1.1.0)
# → Changelog generated
# → Tag created (v1.1.0)
# → Xcode Cloud builds
# → External TestFlight
# → GitHub Release created
# → Slack: "🎉 Version 1.1.0 released!"
```

### App Store
```bash
# Tag triggers ci_release lane
# → Changelog prepared
# → Build & upload to App Store
# → GitHub Release published
# → Slack: "🚀 Submitted to App Store!"
```

---

## 📊 Pipeline Flow

```
Code Change
    ↓
GitHub Push
    ↓
┌─────────────────┬─────────────────┐
│ Docker Tests    │ Xcode Cloud     │
│ (GitHub Actions)│ (macOS)         │
├─────────────────┼─────────────────┤
│ ✅ Swift test   │ ✅ Build        │
│ ✅ Coverage     │ ✅ Sign         │
│                 │ ✅ TestFlight   │
└─────────────────┴─────────────────┘
    ↓                   ↓
Codecov Badge      Slack Alert
    ↓                   ↓
GitHub Release     App Store
```

---

## 🛠️ Troubleshooting

### GitHub Release fails: 401 Unauthorized
```bash
# Check GH_TOKEN has repo scope
# Add to Xcode Cloud Secrets
```

### Slack notification not received
```bash
# Verify webhook URL is correct
# Test with curl:
curl -X POST \
  -H 'Content-type: application/json' \
  --data '{"text":"Test"}' \
  YOUR_WEBHOOK_URL
```

### Docker build takes >10 min
```bash
# Use GitHub Actions cache
- uses: actions/cache@v3
  with:
    path: ~/.docker
    key: docker-${{ hashFiles('Dockerfile') }}
```

### Changelog is empty
```bash
# Check git history
git log --oneline -20

# Adjust range in Fastfile
between: ["HEAD~20", "HEAD"]
```

---

## 🎯 Quick Commands

```bash
# Local Docker tests
docker build -t stackedollama-tests . && docker run --rm stackedollama-tests

# Prepare release
fastlane ios prepare_release

# Test Slack notification
fastlane ios notify_slack_crashlytics status:success

# Full release
fastlane ios release type:minor
```

---

## 📚 Files Added

```
~/StackedOllama-iOS/
├── Dockerfile                        # Swift tests
├── .github/workflows/swift-tests.yml # CI for tests
├── fastlane/Fastfile                 # Extended with new lanes
└── EXTENSIONS_GUIDE.md               # This file
```

---

## ✅ Verification Checklist

- [ ] Docker tests run locally
- [ ] GitHub Actions workflow passes
- [ ] Slack webhook configured
- [ ] Test notification received
- [ ] GitHub Release created on tag
- [ ] Changelog appears in release
- [ ] Codecov badge shows coverage

---

## 🚀 What You Have Now

✅ **Automatic changelog** → GitHub Releases  
✅ **Real-time alerts** → Slack  
✅ **Reproducible tests** → Docker  
✅ **Coverage reports** → Codecov  
✅ **Full automation** → Push to production  

**Your CI/CD is now COMPLETE!** 🎉

---

**Last Updated:** 2026-02-25  
**Status:** Production-Ready ✅
