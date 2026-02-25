# 🚀 Quick Start - iOS CI/CD from Ubuntu

## One-Command Setup

```bash
~/ios-quick-start.sh
```

This will:
1. ✅ Check Ruby & Bundler
2. ✅ Run health check
3. ✅ (Optional) Run Docker tests
4. ✅ Show git status

---

## Manual Setup (5 minutes)

### 1️⃣ Install Dependencies
```bash
# Install Ruby + Bundler (first time only)
sudo apt-get update && sudo apt-get install -y ruby ruby-dev build-essential
gem install bundler

# Install Fastlane
cd ~/StackedOllama-iOS
bundle install
```

### 2️⃣ Health Check
```bash
bundle exec fastlane ios health_check
```

**Expected:** All green checkmarks ✅

### 3️⃣ Test Docker (Optional)
```bash
docker build -t stackedollama-tests .
docker run --rm stackedollama-tests
```

### 4️⃣ Push to GitHub
```bash
git commit -am "test: verify pipeline"
git push origin main
```

**Result:**
- ✅ GitHub Actions runs `swift-tests.yml`
- ✅ Xcode Cloud starts `ios.yml` (ci_build)
- ✅ TestFlight build (internal)
- 💬 Slack notification

---

## Release Flow

### Create Release
```bash
git tag v1.0.0
git push --tags
```

**Result:**
- ✅ GitHub Release with changelog
- ✅ TestFlight build (external)
- 💬 Slack notification

---

## What Happens After Push?

```
git push
   ↓
GitHub Actions (swift-tests.yml)
   ↓
Xcode Cloud (ios.yml)
   ↓
Build + Test
   ↓
TestFlight Upload
   ↓
Slack Notification ✅
```

---

## Timeline

| Action | Time | Result |
|--------|------|--------|
| `git push` | 0 min | Trigger |
| GitHub Actions | 2-5 min | Tests pass |
| Xcode Cloud | 5-10 min | Build complete |
| TestFlight | 10-15 min | Available |
| Slack | 15 min | Notification |

---

## Common Commands

```bash
# Health check
bundle exec fastlane ios health_check

# AI changelog (NEW!)
bundle exec fastlane ios generate_changelog_ai

# Docker test
docker build -t stackedollama-tests . && docker run --rm stackedollama-tests

# Regular build
git push origin main

# Release
git tag v1.0.0 && git push --tags

# Check status
gh run list
~/xccloud-status.sh
```

---

## Troubleshooting

See `TROUBLESHOOTING.md` for common errors and fixes.

---

## Next Steps

1. ✅ Run health check
2. ✅ Push to GitHub
3. ✅ Watch build succeed
4. ✅ Check TestFlight
5. ✅ Celebrate! 🎉

**You're ready to ship!** 🚀
