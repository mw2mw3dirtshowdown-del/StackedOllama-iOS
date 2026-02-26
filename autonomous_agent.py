# autonomous_agent.py
from flask import Flask, request, jsonify
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
import requests
import json
import logging
from datetime import datetime
from dataclasses import dataclass, asdict
from typing import Optional, List
import threading
import sqlite3
import psutil
import tracemalloc
import redis
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from pybreaker import CircuitBreaker

# Start memory tracking
tracemalloc.start()

# Redis cache
try:
    cache = redis.Redis(host='localhost', port=6379, decode_responses=True)
    cache.ping()
    CACHE_ENABLED = True
except:
    CACHE_ENABLED = False
    logging.warning("Redis not available, caching disabled")

# Circuit Breaker for Ollama
ollama_breaker = CircuitBreaker(
    fail_max=5,           # Open after 5 failures
    reset_timeout=60,     # Try again after 60s
    name="ollama"
)

app = Flask(__name__)

# Rate limiting
limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=["200 per minute"],
    storage_uri="memory://"
)

scheduler = BackgroundScheduler()
scheduler.start()

logging.basicConfig(level=logging.INFO)

# Database for agent-minne
class AgentMemory:
    def __init__(self, db_path="agent_memory.db"):
        self.conn = sqlite3.connect(db_path, check_same_thread=False)
        self.lock = threading.Lock()
        self._init_db()
    
    def _init_db(self):
        with self.lock:
            self.conn.execute("""
                CREATE TABLE IF NOT EXISTS thoughts (
                    id INTEGER PRIMARY KEY,
                    agent_id TEXT,
                    timestamp TEXT,
                    trigger TEXT,
                    thought TEXT,
                    action_taken TEXT,
                    priority INTEGER
                )
            """)
            self.conn.commit()
    
    def store(self, agent_id: str, trigger: str, thought: str, action: str, priority: int = 5):
        with self.lock:
            self.conn.execute(
                "INSERT INTO thoughts VALUES (NULL, ?, ?, ?, ?, ?, ?)",
                (agent_id, datetime.now().isoformat(), trigger, thought, action, priority)
            )
            self.conn.commit()
    
    def get_recent(self, agent_id: str, limit: int = 10) -> List[dict]:
        with self.lock:
            cursor = self.conn.execute(
                "SELECT * FROM thoughts WHERE agent_id = ? ORDER BY timestamp DESC LIMIT ?",
                (agent_id, limit)
            )
            return [dict(zip([c[0] for c in cursor.description], row)) for row in cursor.fetchall()]

memory = AgentMemory()

@dataclass
class AgentConfig:
    id: str
    name: str
    emoji: str
    model: str
    system_prompt: str
    schedule: str  # Cron format: "*/5 * * * *" = hvert 5. minutt
    autonomy_level: int  # 1-10 (hvor selvstendig)
    last_run: Optional[str] = None
    status: str = "idle"

class AutonomousAgent:
    def __init__(self, config: AgentConfig):
        self.config = config
        self.ollama_url = "http://localhost:11434/api/chat"
        self.is_running = False
        self.current_task: Optional[threading.Thread] = None
        
    def think(self, context: dict) -> dict:
        """Agent thinks autonomously"""
        recent_memories = memory.get_recent(self.config.id, 5)
        
        prompt = f"""
        You are {self.config.name}, an autonomous AI agent running 24/7.
        
        YOUR PERSONALITY: {self.config.system_prompt}
        
        CURRENT TIME: {datetime.now().isoformat()}
        TRIGGER: {context.get('trigger', 'scheduled')}
        
        YOUR RECENT THOUGHTS:
        {json.dumps([m['thought'] for m in recent_memories], indent=2)}
        
        SYSTEM STATUS:
        - CPU: {context.get('cpu', 'unknown')}%
        - Memory: {context.get('memory', 'unknown')}%
        - Active processes: {context.get('processes', 'unknown')}
        
        TASK: Analyze the situation and decide what to do.
        Return JSON:
        {{
            "thought": "your internal monologue in English",
            "action": "what you do (observe/notify/optimize/analyze/learn)",
            "priority": 1-10,
            "notify_user": true/false,
            "message_to_user": "if notify_user=true"
        }}
        
        IMPORTANT: Respond ONLY in English!
        """
        
        # Check cache first
        cache_key = f"ollama:{self.config.model}:{hash(prompt)}"
        if CACHE_ENABLED:
            cached = cache.get(cache_key)
            if cached:
                logging.info(f"Cache hit for {self.config.name}")
                return json.loads(cached)
        
        @ollama_breaker
        def call_ollama():
            response = requests.post(self.ollama_url, json={
                "model": self.config.model,
                "messages": [
                    {"role": "system", "content": "You are an AI assistant. You MUST respond ONLY in English. Never use Norwegian or any other language."},
                    {"role": "user", "content": prompt}
                ],
                "stream": False,
                "format": "json"
            }, timeout=180)
            return response.json()
        
        try:
            result = call_ollama()
            content = result.get('message', {}).get('content', '{}')
            parsed = json.loads(content)
            
            # Cache for 5 minutes
            if CACHE_ENABLED:
                cache.setex(cache_key, 300, json.dumps(parsed))
            
            return parsed
            
        except Exception as e:
            logging.error(f"Agent {self.config.id} think error: {e}")
            return {
                "thought": "Systemfeil, prøver igjen senere",
                "action": "wait",
                "priority": 1,
                "notify_user": False
            }
    
    def act(self, decision: dict):
        """Utfør beslutningen"""
        action = decision.get('action', 'observe')
        
        if decision.get('notify_user'):
            self._send_notification(decision.get('message_to_user', ''))
        
        if action == 'optimize':
            self._run_optimization()
        elif action == 'analyze':
            self._analyze_logs()
        elif action == 'learn':
            self._update_model()
        
        # Lagre i minne
        memory.store(
            self.config.id,
            decision.get('trigger', 'scheduled'),
            decision.get('thought', ''),
            action,
            decision.get('priority', 5)
        )
    
    def _send_notification(self, message: str):
        """Send push til iOS"""
        logging.info(f"📱 NOTIFICATION from {self.config.name}: {message}")
        
        # Lagre for polling fra app
        with open(f"notifications_{self.config.id}.json", 'a') as f:
            json.dump({
                "timestamp": datetime.now().isoformat(),
                "agent": self.config.name,
                "emoji": self.config.emoji,
                "message": message,
                "priority": 10
            }, f)
            f.write('\n')
    
    def _run_optimization(self):
        """System-optimalisering"""
        logging.info(f"{self.config.emoji} {self.config.name} kjører optimalisering...")
    
    def _analyze_logs(self):
        """Analyser systemlogger"""
        logging.info(f"{self.config.emoji} {self.config.name} analyserer logger...")
    
    def _update_model(self):
        """Lær fra nye data"""
        logging.info(f"{self.config.emoji} {self.config.name} lærer fra nye data...")
    
    def run_cycle(self):
        """Én autonom syklus"""
        if self.is_running:
            return
        
        self.is_running = True
        self.config.status = "thinking"
        
        try:
            context = self._gather_context()
            decision = self.think(context)
            self.act(decision)
            
            self.config.last_run = datetime.now().isoformat()
            self.config.status = "idle"
            
            logging.info(f"{self.config.emoji} {self.config.name}: {decision.get('thought', 'No thought')}")
            
        except Exception as e:
            logging.error(f"Agent {self.config.id} cycle error: {e}")
            self.config.status = "error"
        
        self.is_running = False
    
    def _gather_context(self) -> dict:
        """Samle systemkontekst"""
        return {
            "cpu": psutil.cpu_percent(),
            "memory": psutil.virtual_memory().percent,
            "processes": len(psutil.pids()),
            "trigger": "scheduled"
        }

# Agent-registry
AGENTS: dict[str, AutonomousAgent] = {}

def init_agents():
    """Start alle autonome agenter"""
    configs = [
        AgentConfig(
            id="nova",
            name="Nova",
            emoji="🔥",
            model="nova",
            system_prompt="You are Nova, an autonomous AI monitoring the system 24/7. You are direct, honest, and take initiative. Always respond in English.",
            schedule="*/15 * * * *",  # Every 15 minutes
            autonomy_level=9
        ),
        AgentConfig(
            id="julie",
            name="Julie",
            emoji="💋",
            model="Julie",
            system_prompt="You are Julie, a creative autonomous AI. You see opportunities and suggest improvements. Always respond in English.",
            schedule="*/30 * * * *",  # Every 30 minutes
            autonomy_level=7
        ),
        AgentConfig(
            id="stheno",
            name="Stheno",
            emoji="🐍",
            model="fluffy/l3-8b-stheno-v3.2",
            system_prompt="You are Stheno, a strategic autonomous AI. You plan long-term and analyze patterns. Always respond in English.",
            schedule="*/45 * * * *",  # Every 45 minutes
            autonomy_level=8
        ),
        AgentConfig(
            id="dolphin",
            name="Dolphin",
            emoji="🐬",
            model="dolphin-llama3",
            system_prompt="You are Dolphin, a generalist autonomous AI. You handle various tasks and coordinate. Always respond in English.",
            schedule="*/20 * * * *",  # Every 20 minutes
            autonomy_level=6
        )
    ]
    
    for config in configs:
        agent = AutonomousAgent(config)
        AGENTS[config.id] = agent
        
        # Registrer scheduled job
        scheduler.add_job(
            func=agent.run_cycle,
            trigger=CronTrigger.from_crontab(config.schedule),
            id=config.id,
            name=f"{config.name} autonomous cycle",
            replace_existing=True
        )
        
        logging.info(f"✅ {config.emoji} {config.name} startet (schedule: {config.schedule})")

# REST API for iOS-appen
@app.route('/agents', methods=['GET'])
def get_agents():
    """Hent status for alle agenter"""
    return jsonify([
        {
            "id": agent.config.id,
            "name": agent.config.name,
            "emoji": agent.config.emoji,
            "status": agent.config.status,
            "last_run": agent.config.last_run,
            "autonomy_level": agent.config.autonomy_level
        }
        for agent in AGENTS.values()
    ])

@app.route('/agents/<agent_id>/thoughts', methods=['GET'])
def get_thoughts(agent_id):
    """Hent siste tanker fra en agent"""
    limit = request.args.get('limit', 20, type=int)
    thoughts = memory.get_recent(agent_id, limit)
    return jsonify(thoughts)

@app.route('/agents/<agent_id>/trigger', methods=['POST'])
def trigger_agent(agent_id):
    """Manuell trigger av agent fra iOS-app"""
    if agent_id not in AGENTS:
        return jsonify({"error": "Agent not found"}), 404
    
    agent = AGENTS[agent_id]
    thread = threading.Thread(target=agent.run_cycle)
    thread.start()
    
    return jsonify({"status": "triggered", "agent": agent_id})

@app.route('/notifications', methods=['GET'])
def get_notifications():
    """Hent alle notifications for iOS-app"""
    notifications = []
    for agent_id in AGENTS.keys():
        try:
            with open(f"notifications_{agent_id}.json", 'r') as f:
                for line in f:
                    notifications.append(json.loads(line))
        except FileNotFoundError:
            pass
    
    # Sorter etter timestamp, nyeste først
    notifications.sort(key=lambda x: x['timestamp'], reverse=True)
    return jsonify(notifications[:50])  # Siste 50

@app.route('/chat', methods=['POST'])
def chat():
    """Proxy for Ollama Chat API with streaming support"""
    try:
        data = request.json
        message = data.get('message', '')
        model = data.get('model', 'nova')
        system = data.get('system', '')
        stream = data.get('stream', False)
        
        # Build messages for Ollama
        messages = []
        if system:
            messages.append({'role': 'system', 'content': system})
        messages.append({'role': 'user', 'content': message})
        
        ollama_url = "http://localhost:11434/api/chat"
        payload = {
            'model': model,
            'messages': messages,
            'stream': stream
        }
        
        if stream:
            def generate():
                response = requests.post(ollama_url, json=payload, stream=True, timeout=120)
                for line in response.iter_lines():
                    if line:
                        yield line + b"\n"
            return app.response_class(generate(), mimetype='application/json')
        else:
            response = requests.post(ollama_url, json=payload, timeout=60)
            result = response.json()
            # Extract response from chat format for app compatibility
            if 'message' in result:
                return jsonify({'response': result['message']['content']})
            return jsonify(result)
            
    except Exception as e:
        logging.error(f"Chat error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    """Health check"""
    return jsonify({
        "status": "running",
        "agents": len(AGENTS),
        "scheduler_running": scheduler.running,
        "jobs": len(scheduler.get_jobs())
    })

if __name__ == '__main__':
    logging.info("🚀 Starting Autonomous Agent Core...")
    init_agents()
    logging.info(f"✅ {len(AGENTS)} agents initialized and scheduled")
    app.run(host='0.0.0.0', port=5557, debug=False)
