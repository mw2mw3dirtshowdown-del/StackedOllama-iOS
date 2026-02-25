# Autonomous Agent Architecture ✅

## System Overview

```
┌─────────────────────────────────────────┐
│      AUTONOMOUS AGENT CORE (24/7)      │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │  Nova   │ │  Julie  │ │ Stheno  │   │
│  │ (5 min) │ │(10 min) │ │(15 min) │   │
│  └────┬────┘ └────┬────┘ └────┬────┘   │
│       └───────────┼───────────┘         │
│                   ▼                     │
│           ┌─────────────┐               │
│           │  Scheduler  │               │
│           │ (APScheduler)│              │
│           └──────┬──────┘               │
│                  │                      │
│           ┌──────┴──────┐               │
│           │   Memory    │               │
│           │  (SQLite)   │               │
│           └─────────────┘               │
└──────────────────┼──────────────────────┘
                   │ REST API (port 5557)
┌──────────────────┼──────────────────────┐
│     iOS APP      │    (viewer)          │
│  ┌─────────────┐ │  ┌─────────────┐     │
│  │   Live Feed │◄─┘  │ Notifications│     │
│  │  (polling)  │     │  (viktige)  │     │
│  └─────────────┘     └─────────────┘     │
└─────────────────────────────────────────┘
```

## Backend (Linux Server)

### Service: autonomous-agents.service
**Location**: `/etc/systemd/system/autonomous-agents.service`
**Port**: 5557
**Status**: ✅ Running

```bash
# Control
sudo systemctl status autonomous-agents
sudo systemctl restart autonomous-agents
sudo journalctl -u autonomous-agents -f

# Logs
tail -f /var/log/syslog | grep autonomous
```

### Agents

| Agent | Schedule | Autonomy | Model |
|-------|----------|----------|-------|
| 🔥 Nova | Every 5 min | 9/10 | nova |
| 💋 Julie | Every 10 min | 7/10 | Julie |
| 🐍 Stheno | Every 15 min | 8/10 | fluffy/l3-8b-stheno-v3.2 |
| 🐬 Dolphin | Every 7 min | 6/10 | dolphin-llama3 |

### Agent Cycle

1. **Gather Context** - CPU, memory, processes
2. **Think** - LLM generates decision (JSON)
3. **Act** - Execute action (observe/notify/optimize/analyze/learn)
4. **Store** - Save thought to SQLite memory
5. **Notify** - Send to iOS if important

### API Endpoints

```bash
# Health check
GET http://192.168.1.198:5557/health

# Get all agents
GET http://192.168.1.198:5557/agents

# Get agent thoughts
GET http://192.168.1.198:5557/agents/nova/thoughts?limit=20

# Trigger agent manually
POST http://192.168.1.198:5557/agents/nova/trigger

# Get notifications
GET http://192.168.1.198:5557/notifications
```

## iOS App (Viewer)

### Features

1. **Live Feed** - Poll agent status every 5 seconds
2. **Thought Stream** - View agent's internal monologue
3. **Manual Trigger** - Force agent to run cycle
4. **Notifications** - See important alerts from agents
5. **Status Indicators** - Real-time agent state

### Integration

```swift
// Poll autonomous agents
func startLiveMode() {
    modeTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
        Task { await self.pollAutonomousAgents() }
    }
}

// Get agent status
let statuses = try await autonomous.getAgentStatus()

// Trigger agent
try await autonomous.triggerAgent(agentId: "nova")

// Load thoughts
let thoughts = try await autonomous.getThoughts(agentId: "nova")
```

## Agent Memory (SQLite)

**Database**: `/home/sondre/agent_memory.db`

```sql
CREATE TABLE thoughts (
    id INTEGER PRIMARY KEY,
    agent_id TEXT,
    timestamp TEXT,
    trigger TEXT,
    thought TEXT,
    action_taken TEXT,
    priority INTEGER
);
```

## Agent Decision Format

```json
{
    "thought": "CPU usage is high, should investigate",
    "action": "analyze",
    "priority": 7,
    "notify_user": true,
    "message_to_user": "⚠️ High CPU detected (85%)"
}
```

## Actions

- **observe** - Just watch, no action
- **notify** - Send notification to iOS
- **optimize** - Run system optimization
- **analyze** - Analyze logs/patterns
- **learn** - Update model/knowledge

## Autonomy Levels

- **1-3**: Low - Only observes, rarely acts
- **4-6**: Medium - Acts on clear issues
- **7-9**: High - Proactive, takes initiative
- **10**: Full - Complete autonomy (dangerous!)

## Production Setup

### Requirements
```bash
pip3 install flask apscheduler psutil
```

### Systemd Service
```bash
sudo systemctl enable autonomous-agents
sudo systemctl start autonomous-agents
```

### Monitoring
```bash
# Watch logs
sudo journalctl -u autonomous-agents -f

# Check health
curl http://192.168.1.198:5557/health

# View agent status
curl http://192.168.1.198:5557/agents | jq
```

## Testing

```bash
# Trigger Nova manually
curl -X POST http://192.168.1.198:5557/agents/nova/trigger

# Check thoughts
curl http://192.168.1.198:5557/agents/nova/thoughts | jq

# Get notifications
curl http://192.168.1.198:5557/notifications | jq
```

## Architecture Benefits

✅ **Agents run 24/7** - Independent of iOS app
✅ **Persistent memory** - SQLite stores all thoughts
✅ **Scheduled execution** - Cron-like scheduling
✅ **Real-time monitoring** - iOS app polls status
✅ **Manual override** - Trigger agents from app
✅ **Notifications** - Important events pushed to iOS
✅ **Scalable** - Add more agents easily
✅ **Testable** - REST API for all operations

## Next Steps

1. ✅ Backend running (port 5557)
2. ✅ iOS app integrated
3. ⏳ Wait for first agent cycle (5-15 min)
4. ⏳ Test notifications
5. ⏳ Add push notifications (APNs)
6. ⏳ Add streaming (SSE/WebSocket)

---

**Status**: Production-ready autonomous agent system 🤖
**Version**: 1.0
**Date**: 2026-02-25
