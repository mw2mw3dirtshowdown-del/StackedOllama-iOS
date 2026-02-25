# 🚀 Advanced Features - Full Speed Upgrade

## What's Available

1. ✅ **Code Coverage** → Codecov/Coveralls
2. ✅ **Canary Beta** → Internal testing
3. ✅ **Performance Monitoring** → Instruments
4. ✅ **Version Auditing** → Monotonic build numbers
5. ✅ **Signing Verification** → Match profiles
6. ✅ **Dynamic Badges** → README status

---

## 1. Code Coverage (Codecov)

### Add to Fastfile
```ruby
desc "Full CI with code coverage"
lane :ci_build_with_coverage do
  # Run tests with coverage
  run_tests(
    scheme: "StackedOllama",
    devices: ["iPhone 15"],
    code_coverage: true,
    output_directory: "./Coverage"
  )
  
  # Upload to Codecov
  sh("curl -Os https://uploader.codecov.io/latest/linux/codecov")
  sh("chmod +x codecov")
  sh("./codecov -t ${CODECOV_TOKEN}")
end
```

### Add Secret
- Xcode Cloud: `CODECOV_TOKEN`
- GitHub Actions: `CODECOV_TOKEN`

### Get Token
1. Go to https://codecov.io
2. Connect GitHub repo
3. Copy token

---

## 2. Canary Beta Lane

### Add to Fastfile
```ruby
desc "Upload canary build to internal TestFlight"
lane :ci_canary do
  build_app(
    scheme: "StackedOllama",
    export_method: "app-store",
    output_directory: "./canary_build"
  )
  
  upload_to_testflight(
    distribute_external: false,
    groups: ["Internal_Team"],
    changelog: "Canary build for internal testing"
  )
  
  slack(
    message: "🐤 Canary build uploaded to internal TestFlight",
    channel: "#beta"
  ) if ENV['SLACK_WEBHOOK_URL']
end
```

### Usage
```bash
# Manual
bundle exec fastlane ios ci_canary

# Auto on PR with 'canary' label
# (add to GitHub Actions workflow)
```

---

## 3. Version Auditing

### Add to Fastfile
```ruby
desc "Verify build number increases monotonically"
lane :audit_version_number do
  current = get_build_number
  previous_file = "previous_build.txt"
  previous = File.exist?(previous_file) ? File.read(previous_file).strip.to_i : 0
  
  UI.message "Current: #{current}, Previous: #{previous}"
  
  if current.to_i <= previous
    UI.user_error!("❌ Build number must be greater than #{previous}!")
  end
  
  File.write(previous_file, current)
  UI.success "✅ Build number verified"
end
```

### Use in Release
```ruby
lane :ci_release do
  audit_version_number  # ← Add this
  prepare_release
  # ... rest of lane
end
```

---

## 4. Performance Monitoring

### Add to Fastfile
```ruby
desc "Collect performance data with Instruments"
lane :performance_report do
  timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
  trace_path = "./PerfReports/perf-#{timestamp}.trace"
  
  sh("mkdir -p PerfReports")
  
  # Run Instruments (requires macOS)
  sh(%{
    xcrun instruments \
      -w "iPhone 15" \
      -t "Time Profiler" \
      -D "#{trace_path}" \
      MyApp
  })
  
  slack(
    message: "📊 Performance report generated",
    channel: "#performance"
  ) if ENV['SLACK_WEBHOOK_URL']
end
```

---

## 5. Dynamic README Badges

### Add to README.md
```markdown
[![Release](https://img.shields.io/github/v/release/YOUR_USER/StackedOllama-iOS?label=release&color=brightgreen)](https://github.com/YOUR_USER/StackedOllama-iOS/releases)
[![Codecov](https://codecov.io/gh/YOUR_USER/StackedOllama-iOS/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_USER/StackedOllama-iOS)
[![Xcode Cloud](https://img.shields.io/badge/Xcode%20Cloud-Build-brightgreen)](https://appstoreconnect.apple.com)
```

These update automatically! 🎉

---

## 6. Signing Verification

### Add to Fastfile
```ruby
desc "Verify signing assets are in sync"
lane :audit_signing_assets do
  # Check provisioning profile
  bundle_id = CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)
  
  UI.message "Verifying signing for #{bundle_id}"
  
  # This will fail if profiles don't match
  build_app(
    scheme: "StackedOllama",
    skip_archive: true,
    skip_codesigning: false
  )
  
  UI.success "✅ Signing assets verified"
end
```

---

## Quick Commands

```bash
# Code coverage
bundle exec fastlane ios ci_build_with_coverage

# Canary beta
bundle exec fastlane ios ci_canary

# Version audit
bundle exec fastlane ios audit_version_number

# Performance report (macOS only)
bundle exec fastlane ios performance_report

# Signing verification
bundle exec fastlane ios audit_signing_assets
```

---

## Secrets Needed

Add these to Xcode Cloud & GitHub Actions:

- `CODECOV_TOKEN` - Code coverage
- `COVERALLS_TOKEN` - Alternative to Codecov
- `SLACK_WEBHOOK_URL` - Notifications
- `ANTHROPIC_API_KEY` - AI changelog (optional)

---

## What You Get

```
✅ Code coverage tracking
✅ Canary beta testing
✅ Version auditing
✅ Performance monitoring
✅ Signing verification
✅ Dynamic badges
```

**Your pipeline is now PRODUCTION-GRADE!** 🚀

---

## Implementation Priority

**High Priority:**
1. Code coverage (Codecov)
2. Version auditing
3. Dynamic badges

**Medium Priority:**
4. Canary beta
5. Signing verification

**Low Priority:**
6. Performance monitoring (requires macOS)

---

**Start with code coverage - it's the most valuable!** 📊
