# 🔧 Troubleshooting Guide

## Common Errors & Quick Fixes

### 1. Missing API Key
**Error:** `[FASTLANE] Missing API key` or `Login failed`

**Where:** Xcode Cloud logs

**Fix:**
1. Go to Xcode Cloud → Settings → Secrets
2. Add these secrets:
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_KEY_ID`
   - `APP_STORE_CONNECT_PRIVATE_KEY`

---

### 2. No Matching Provisioning Profile
**Error:** `No matching provisioning profile found`

**Where:** Build logs

**Fix:**
1. Go to Apple Developer → Certificates, Identifiers & Profiles
2. Create App Store Distribution profile
3. Name it `MyApp_Production` (or update Fastfile)

---

### 3. GitHub API Unauthorized
**Error:** `[FASTLANE] Unauthorized (GitHub API)`

**Where:** GitHub Actions logs

**Fix:**
1. Create new Personal Access Token (PAT)
2. Scope: `repo`
3. Add as `GH_TOKEN` in GitHub Secrets

---

### 4. Docker Test Fails
**Error:** `No such file or directory` in Docker

**Where:** `docker run` output

**Fix:**
- Ensure `Package.swift`, `Sources/`, `Tests/` are in root folder
- Run `docker build` from project root

---

### 5. Slack Webhook Failed
**Error:** No Slack message received

**Where:** Slack channel

**Fix:**
1. Test webhook URL in browser
2. Verify `CRASHLYTICS_SLACK_WEBHOOK_URL` secret matches
3. Check Slack app permissions

---

## Health Check

Run this before every build:
```bash
cd ~/StackedOllama-iOS
bundle exec fastlane ios health_check
```

**Expected output:**
```
🔐 Checking GitHub token...
✅ GH_TOKEN present
🔑 Checking App Store Connect API...
✅ App Store Connect API configured
✅ Slack webhook URL is set
🎉 Health check passed – ready to build!
```

---

## Quick Commands

### Test locally
```bash
# Docker tests
docker build -t stackedollama-tests .
docker run --rm stackedollama-tests

# Health check
bundle exec fastlane ios health_check
```

### Trigger build
```bash
# Regular build
git commit -am "test: verify pipeline"
git push origin main

# Release build
git tag v1.0.0
git push --tags
```

### Check status
```bash
# GitHub Actions
gh run list

# Xcode Cloud
~/xccloud-status.sh
```

---

## Getting Help

1. Check logs in GitHub Actions
2. Check logs in Xcode Cloud
3. Run health check
4. Check this guide

**Still stuck?** Check the error message and search above! 🔍
