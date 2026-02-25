# 🧪 Dry Run Testing Guide

## Test Everything Locally (No External Calls)

Before pushing to GitHub or connecting Xcode Cloud, test everything locally!

---

## Quick Dry Run

```bash
cd ~/StackedOllama-iOS
DISABLE_SLACK=true SKIP_ARCHIVE=true bundle exec fastlane ios dry_run
```

**What it does:**
1. ✅ Health check (verify secrets)
2. ✅ Version audit (monotonic build numbers)
3. ✅ Generate changelog (AI or git)
4. ✅ Build app (no upload)
5. ✅ Verify IPA signature
6. ✅ Mock Slack notification

**Time:** ~5 minutes

---

## Step-by-Step Testing

### 1. Health Check
```bash
bundle exec fastlane ios health_check
```

**Expected:**
```
🔐 Checking GitHub token...
✅ GH_TOKEN present
🔑 Checking App Store Connect API...
✅ App Store Connect API configured
🎉 Health check passed – ready to build!
```

---

### 2. AI Changelog (Local)
```bash
bundle exec fastlane ios generate_changelog_ai
cat CHANGELOG.md
```

**Expected:** Beautiful AI-generated changelog!

---

### 3. Version Audit
```bash
bundle exec fastlane ios audit_version_number
```

**Expected:**
```
Current: 42, Previous: 41
✅ Build number verified
```

---

### 4. Build (No Upload)
```bash
DISABLE_SLACK=true bundle exec fastlane ios ci_build
```

**Expected:** Build succeeds, no external API calls

---

### 5. Full Dry Run
```bash
DISABLE_SLACK=true SKIP_ARCHIVE=true USE_AI_CHANGELOG=true \
  bundle exec fastlane ios dry_run
```

**Expected:**
```
🧪 DRY RUN - Testing pipeline locally
1️⃣ Running health check...
2️⃣ Auditing version number...
3️⃣ Generating changelog...
4️⃣ Building app...
5️⃣ Verifying IPA signature...
6️⃣ Mock Slack notification...
🎉 DRY RUN COMPLETE - Everything works!
```

---

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `DISABLE_SLACK` | Skip Slack notifications | `true` |
| `SKIP_ARCHIVE` | Skip archive step (faster) | `true` |
| `USE_AI_CHANGELOG` | Use AI instead of git log | `true` |
| `SKIP_UPLOAD` | Build IPA but don't upload | `true` |

---

## Verify IPA Signature

```bash
# After dry run
codesign --verify --verbose ./dry_run_build/*.ipa
codesign -d --entitlements - ./dry_run_build/*.ipa
```

**Expected:** No errors, valid signature

---

## Mock Slack Webhook

### Option 1: Disable Slack
```bash
DISABLE_SLACK=true bundle exec fastlane ios ci_build
```

### Option 2: Use Test Webhook
1. Go to https://webhook.site
2. Copy URL
3. Set as `SLACK_WEBHOOK_URL`
4. Run lane
5. Check webhook.site for payload

---

## Test Checklist

Before pushing to GitHub:

- [ ] Health check passes
- [ ] AI changelog generates
- [ ] Version audit works
- [ ] Build succeeds (no upload)
- [ ] IPA signature valid
- [ ] Slack mock works
- [ ] Dry run completes

---

## Common Issues

### "Missing secret"
```bash
# Load .env file
source .env
bundle exec fastlane ios health_check
```

### "No matching provisioning profile"
```bash
# Check profiles in Apple Developer
# Update export_options in Fastfile
```

### "xcpretty not found"
```bash
gem install xcpretty
```

### "Codesign failed"
```bash
# Check Keychain has valid certificates
security find-identity -v -p codesigning
```

---

## When Ready to Push

After all dry runs pass:

```bash
# 1. Commit changes
git add .
git commit -m "feat: complete iOS CI/CD pipeline"

# 2. Push to GitHub
git push origin main

# 3. Watch GitHub Actions
gh run list

# 4. Create release (when ready)
git tag v1.0.0
git push --tags
```

---

## Timeline

| Step | Time | What Happens |
|------|------|--------------|
| Dry run | 5 min | Local testing |
| git push | 0 min | Trigger CI |
| GitHub Actions | 2-5 min | Tests run |
| Xcode Cloud | 5-10 min | Build |
| TestFlight | 10-15 min | Upload |
| Slack | 15 min | Notification |

---

## Pro Tips

1. **Always dry run first** - Catch issues early
2. **Use SKIP_ARCHIVE=true** - Faster testing
3. **Check IPA signature** - Verify signing works
4. **Mock Slack** - Test without spamming team
5. **Load .env** - Keep secrets local

---

## Next Steps

After successful dry run:

1. ✅ Push to GitHub
2. ✅ Connect Xcode Cloud
3. ✅ Add Apple secrets
4. ✅ Configure Slack webhook
5. ✅ Create first release

**You're ready!** 🚀
