# 🔔 Slack Integration Setup

## 1. Create Slack Webhook

1. Go to: https://api.slack.com/apps
2. Click **Create New App** → **From scratch**
3. Name: "Xcode Cloud CI"
4. Select workspace
5. Click **Incoming Webhooks** → Enable
6. Click **Add New Webhook to Workspace**
7. Select channel: `#ios-ci`
8. Copy webhook URL: `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX`

---

## 2. Add to Xcode Cloud

### In App Store Connect:

1. Go to **Xcode Cloud** → **Settings**
2. Click **Environment Variables**
3. Add secret:
   - Name: `SLACK_WEBHOOK_URL`
   - Value: `https://hooks.slack.com/services/...`
   - Type: Secret

---

## 3. Test Notification

```bash
# Test from Ubuntu
curl -X POST \
  -H 'Content-type: application/json' \
  --data '{"text":"🧪 Test from Ubuntu!"}' \
  https://hooks.slack.com/services/YOUR_WEBHOOK_URL
```

---

## 4. Notifications You'll Get

### ✅ Success:
```
✅ Build #42 (v1.2.0) – main – klar for TestFlight!
Build Number: 42
Version: 1.2.0
Branch: main
```

### ❌ Failure:
```
❌ Build #42 failed: Code signing error
```

### 🎉 Release:
```
🎉 Version 1.2.0 released!
```

---

## 5. Customize Messages

Edit `fastlane/Fastfile`:

```ruby
slack(
  message: "Your custom message",
  slack_url: ENV['SLACK_WEBHOOK_URL'],
  channel: "#ios-ci",
  success: true,
  payload: {
    "Custom Field" => "Custom Value"
  }
)
```

---

## 6. Multiple Channels

```ruby
# Success → #ios-ci
# Failure → #ios-alerts
slack(
  message: "...",
  channel: success? ? "#ios-ci" : "#ios-alerts"
)
```

---

**Your team will now get instant CI/CD notifications!** 🔔
