# 🚀 Fastlane Usage Guide

## 📋 Available Lanes

### 1. CI Build (Automatic)
```bash
fastlane ios ci_build
```

**What it does:**
- ✅ Increments build number
- ✅ Generates changelog from last 20 commits
- ✅ Builds .ipa
- ✅ Uploads to TestFlight
  - **Regular commits**: Internal testers only
  - **Release tags** (v1.0.0): External testers

**Triggered by:**
- Xcode Cloud (automatic on push)
- Manual: `~/trigger-xcode-cloud.sh`

---

### 2. Development Build
```bash
fastlane ios dev_build
```

**What it does:**
- Builds development .ipa
- No TestFlight upload
- For local testing

---

### 3. Release (Create Version Tag)
```bash
# Patch release (1.0.0 → 1.0.1)
fastlane ios release

# Minor release (1.0.1 → 1.1.0)
fastlane ios release type:minor

# Major release (1.1.0 → 2.0.0)
fastlane ios release type:major
```

**What it does:**
- ✅ Increments version number
- ✅ Commits version bump
- ✅ Creates git tag (v1.0.1)
- ✅ Pushes to remote
- ✅ Triggers Xcode Cloud build (if configured)
- ✅ External TestFlight distribution (because of tag)

---

## 🎯 Workflow Examples

### Regular Development
```bash
# 1. Make changes
git add .
git commit -m "Add new feature"
git push

# → Xcode Cloud builds automatically
# → Internal TestFlight only
```

### Release to External Testers
```bash
# 1. Create release
fastlane ios release type:minor

# → Version bumped: 1.0.0 → 1.1.0
# → Tag created: v1.1.0
# → Pushed to GitHub
# → Xcode Cloud builds
# → External TestFlight distribution! 🎉
```

### Manual Build Trigger
```bash
# Trigger specific branch
~/trigger-xcode-cloud.sh master

# Trigger release branch
~/trigger-xcode-cloud.sh release/v1.2.0
```

---

## 📊 TestFlight Distribution Logic

| Scenario | Internal Testers | External Testers |
|----------|------------------|------------------|
| Regular commit | ✅ Yes | ❌ No |
| Release tag (v1.0.0) | ✅ Yes | ✅ Yes |

**Release tag pattern:** `v1.0.0`, `v2.3.1`, `1.0.0` (all work)

---

## 🔧 Configuration

### Bundle ID
Edit in `Fastfile`:
```ruby
"com.yourcompany.stackedollama" => "StackedOllama_Production"
```

### Provisioning Profile
Create in App Store Connect:
- Name: `StackedOllama_Production`
- Type: App Store
- Bundle ID: `com.yourcompany.stackedollama`

### Changelog Length
Edit in `Fastfile`:
```ruby
between: ["HEAD~20", "HEAD"]  # Last 20 commits
```

---

## 🚨 Troubleshooting

### Build fails: "No matching provisioning profile"
```bash
# Check bundle ID matches
# App Store Connect → Certificates → Profiles → StackedOllama_Production
```

### TestFlight not distributing externally
```bash
# Check if tag exists
git describe --exact-match --tags HEAD

# Should output: v1.0.0 (or similar)
```

### Version number not incrementing
```bash
# Manually increment
agvtool next-version -all

# Or in Fastfile, add:
increment_version_number(bump_type: "patch")
```

---

## 📚 Quick Reference

```bash
# Development
git push                              # → Internal TestFlight

# Release
fastlane ios release                  # → External TestFlight

# Manual trigger
~/trigger-xcode-cloud.sh master       # → Build specific branch

# Check build status
~/xccloud-status.sh <build-id>        # → Monitor build
```

---

**Your CI/CD is now production-ready!** 🚀
