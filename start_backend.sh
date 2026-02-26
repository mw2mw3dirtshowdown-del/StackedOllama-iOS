#!/bin/bash
# start_backend.sh

echo "🚀 Starting Autonomous Agent Core..."
nohup python3 autonomous_agent.py > autonomous_agent.log 2>&1 &
PID=$!
echo $PID > backend.pid
echo "✅ Backend started with PID $PID. Logs: autonomous_agent.log"
