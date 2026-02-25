# 🤖 AI-Powered Changelog

## Overview

Generate beautiful, user-focused changelogs automatically using AI!

**Two options:**
1. **Local Ollama** (free, private, fast) ✅ **RECOMMENDED**
2. **Anthropic Claude** (requires API key, costs money)

---

## Option 1: Local Ollama (Free!) 🆓

### Setup
Already done! You have Ollama with `qwen2.5-coder` installed.

### Usage
```bash
cd ~/StackedOllama-iOS
bundle exec fastlane ios generate_changelog_ai
```

**What it does:**
1. Gets last 10 commits
2. Sends to local Ollama (qwen2.5-coder)
3. AI writes user-friendly changelog
4. Saves to `CHANGELOG.md`

**Example output:**
```markdown
* Added new AI-powered features for better user experience
* Fixed critical bug in authentication flow
* Improved performance by 30% through caching
* Updated dependencies to latest versions
```

---

## Option 2: Anthropic Claude (Paid)

### Setup
1. Get API key from https://console.anthropic.com
2. Add to secrets:
   - Xcode Cloud: `ANTHROPIC_API_KEY`
   - GitHub Actions: `ANTHROPIC_API_KEY`

### Add to Fastfile
```ruby
lane :generate_changelog_anthropic do
  commits = sh("git log --oneline -n 10 --pretty=format:'%h %s'").strip
  
  prompt = "Write a concise changelog from these commits:\n\n#{commits}"
  
  ai_response = sh(%{
    curl -s https://api.anthropic.com/v1/messages \
      -X POST \
      -H "Content-Type: application/json" \
      -H "x-api-key: $ANTHROPIC_API_KEY" \
      -d '{
            "model":"claude-3-haiku-20240307",
            "messages":[{"role":"user","content":"#{prompt}"}],
            "max_tokens":200,
            "temperature":0
          }' | jq -r '.content[0].text'
  }).strip
  
  File.write("CHANGELOG.md", ai_response)
  UI.success "🖋️  AI changelog generated"
end
```

---

## Integrate with Release Flow

### Automatic AI Changelog on Release
```ruby
lane :ci_release do
  generate_changelog_ai  # ← Add this line
  increment_version_number(...)
  # ... rest of lane
end
```

Now every release gets an AI-generated changelog! 🎉

---

## Comparison

| Feature | Local Ollama | Anthropic Claude |
|---------|--------------|------------------|
| Cost | Free | ~$0.001/request |
| Speed | Fast (local) | Medium (API) |
| Privacy | 100% private | Sent to API |
| Quality | Excellent | Excellent |
| Setup | Already done! | Need API key |

**Recommendation:** Use local Ollama! It's free, fast, and private. ✅

---

## Advanced: Custom Prompts

### Make it Norwegian
```ruby
prompt = "Du er en hjelpsom assistent som skriver korte, bruker-fokuserte changelog-oppføringer på norsk. Bruk bullet points. Oppsummer disse commits:\n\n#{commits}"
```

### Make it funny
```ruby
prompt = "Write a funny, engaging changelog with emojis from these commits:\n\n#{commits}"
```

### Make it technical
```ruby
prompt = "Write a detailed technical changelog for developers from these commits:\n\n#{commits}"
```

---

## Test It Now!

```bash
cd ~/StackedOllama-iOS
bundle exec fastlane ios generate_changelog_ai
cat CHANGELOG.md
```

**Magic!** 🪄✨

---

## Resources

- **Ollama Docs**: https://ollama.ai/docs
- **Anthropic API**: https://docs.anthropic.com
- **Fastlane AI**: https://fastlane.tools/actions/#ai-assistants

---

**You now have AI writing your changelogs!** 🤖🚀
