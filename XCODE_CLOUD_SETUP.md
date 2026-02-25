# 🚀 Xcode Cloud Setup - StackedOllama iOS

## 📋 Prerequisites

✅ App is production-ready (see PRODUCTION.md)
✅ Xcode project exists (StackedOllama.xcodeproj)
✅ Git repository (needs to be pushed to GitHub/GitLab)

---

## 🔧 Step 1: Push to Git

```bash
cd ~/StackedOllama-iOS

# Initialize if not done
git init

# Add all files
git add .

# Commit
git commit -m "Production-ready iOS app with AI agents"

# Add remote (choose one):
# GitHub:
git remote add origin https://github.com/YOUR_USERNAME/StackedOllama-iOS.git

# GitLab:
git remote add origin https://gitlab.com/YOUR_USERNAME/StackedOllama-iOS.git

# Push
git push -u origin main
```

---

## ☁️ Step 2: App Store Connect Setup

### 1. Open App Store Connect
- Go to: https://appstoreconnect.apple.com
- Sign in with your Apple Developer account

### 2. Navigate to Xcode Cloud
- Click **Xcode Cloud** in the sidebar
- Click **Get Started** or **Connect Repository**

### 3. Connect Repository
**Choose your git host:**
- ✅ GitHub (recommended)
- GitLab
- Bitbucket
- SSH (custom)

**Select repository:**
- `StackedOllama-iOS`

**Authorize:**
- Grant Xcode Cloud access to your repo

### 4. Configure Workflow

**Branch:**
- `main` (or `master`)

**Triggers:**
- ✅ On push to main
- ✅ On pull request (optional)
- Manual builds (always available)

**Scheme:**
- `StackedOllama` (auto-detected)

**Build Actions:**
- ✅ Archive
- ✅ Test (if you have tests)

**Devices for Testing:**
- iPhone 15 Pro (iOS 17.0+)
- iPhone 14 (iOS 16.0+)
- iPad Pro 12.9" (optional)

**Parallel Testing:**
- ✅ Enable (faster builds)

### 5. Signing Configuration

**Automatic Signing (Recommended):**
- ✅ Use automatic signing
- Team: Your Apple Developer Team
- Bundle ID: `com.yourcompany.stackedollama`

**Manual Signing (Advanced):**
- Upload provisioning profiles
- Upload certificates

### 6. TestFlight Distribution

**Auto-distribute to TestFlight:**
- ✅ Yes (recommended)
- Groups: Internal Testers
- External Testers: Add later

**Build Notes:**
- Auto-generated from commit messages
- Or custom notes

### 7. Environment Variables (Optional)

If your app needs API keys:
```
OLLAMA_API_URL=https://your-cloudflare-tunnel.com
API_KEY=your_secret_key
```

### 8. Notifications

**Email:**
- ✅ Build success
- ✅ Build failure
- ✅ TestFlight ready

**Slack (Optional):**
- Add webhook URL
- Channel: #ios-builds

---

## 🎯 Step 3: Start First Build

### Option A: Manual Build
1. Go to Xcode Cloud dashboard
2. Click **Start Build**
3. Select branch: `main`
4. Click **Build**

### Option B: Push to Trigger
```bash
cd ~/StackedOllama-iOS
git add .
git commit -m "Trigger Xcode Cloud build"
git push
```

---

## 📊 Step 4: Monitor Build

### In App Store Connect:
- Go to **Xcode Cloud** → **Builds**
- Click on your build
- Watch logs in real-time
- See artifacts (IPA, logs, test results)

### Build Stages:
1. ⏳ Queued
2. 🔨 Building
3. 🧪 Testing
4. 📦 Archiving
5. ✅ Success → TestFlight
6. ❌ Failed → Check logs

---

## 🐧 Step 5: Linux Helper Script (Optional)

Monitor builds from Linux:

```bash
# Create script
cat > ~/xccloud-status.sh << 'EOF'
#!/bin/bash
# Xcode Cloud Build Status Checker

BUILD_ID="$1"
ISSUER_ID="your-issuer-id"
KEY_ID="your-key-id"
KEY_FILE="~/AuthKey_XXXXX.p8"

if [ -z "$BUILD_ID" ]; then
    echo "Usage: $0 <build-id>"
    exit 1
fi

# Generate JWT token (requires jq and openssl)
# ... (implementation details)

# Poll build status
curl -H "Authorization: Bearer $TOKEN" \
     "https://api.appstoreconnect.apple.com/v1/builds/$BUILD_ID"
EOF

chmod +x ~/xccloud-status.sh
```

---

## 🎓 Recommended Workflow Settings

### For StackedOllama iOS:

**Repository:** GitHub (public or private)
**Branch:** `main`
**Triggers:**
- ✅ Push to main
- ✅ Pull requests to main

**Scheme:** StackedOllama
**Actions:**
- ✅ Archive
- ✅ Test (StackedOllamaTests.swift)

**Test Devices:**
- iPhone 15 Pro (iOS 17.0)
- iPhone 14 (iOS 16.0)

**Signing:** Automatic
**TestFlight:** Auto-distribute to Internal Testers

**Notifications:**
- Email: your@email.com
- Slack: #ios-builds (optional)

---

## 🔥 Quick Checklist

Before starting Xcode Cloud:

- [ ] Code is production-ready
- [ ] Git repo exists locally
- [ ] Pushed to GitHub/GitLab
- [ ] Apple Developer account active
- [ ] App Store Connect access
- [ ] Bundle ID registered
- [ ] Signing configured in Xcode
- [ ] Info.plist has all permissions
- [ ] Tests pass locally

---

## 🚨 Troubleshooting

### Build Fails: Signing Error
- Check automatic signing is enabled
- Verify team is selected
- Ensure bundle ID is registered

### Build Fails: Missing Permissions
- Add to Info.plist:
  - NSMicrophoneUsageDescription
  - NSSpeechRecognitionUsageDescription
  - UIBackgroundModes (audio)

### Build Fails: Dependencies
- Ensure all Swift packages are in git
- Check Package.swift or .xcodeproj

### TestFlight Not Receiving Build
- Check auto-distribution is enabled
- Verify internal testers are added
- Wait 5-10 minutes for processing

---

## 📱 After First Successful Build

1. **TestFlight:**
   - Open TestFlight app on iPhone
   - Accept invite
   - Install build
   - Test app

2. **Iterate:**
   - Make changes
   - Commit & push
   - Xcode Cloud builds automatically
   - New build in TestFlight

3. **Production:**
   - When ready: Submit for App Store Review
   - Add screenshots, description
   - Set pricing
   - Submit

---

## 🎯 Next Steps

1. Push code to GitHub
2. Connect repo in App Store Connect
3. Configure workflow (use settings above)
4. Start first build
5. Monitor in dashboard
6. Test in TestFlight
7. Iterate!

**Your app is ready for the world!** 🚀📱

---

**Last Updated:** 2026-02-25
**Status:** Ready for Xcode Cloud ✅
