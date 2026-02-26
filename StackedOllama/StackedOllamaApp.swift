import SwiftUI
import AVFoundation
import Speech
import os

@main
struct StackedOllamaApp: App {
    var body: some Scene {
        WindowGroup {
            StackedAgentView()
        }
    }
}

// MARK: - Service Protocols
protocol LLMService {
    func generate(model: String, prompt: String, systemPrompt: String) async throws -> String
}

protocol AudioService {
    func synthesize(_ text: String) async throws -> Data
}

// MARK: - Errors
enum OllamaError: Error {
    case network(URLError)
    case decoding
    case api(message: String)
}

// MARK: - Agent Protocol
protocol Agent {
    var id: String { get }
    var name: String { get }
    var emoji: String { get }
    var description: String { get }
    var model: String { get }
    var systemPrompt: String { get }
    var gradientColors: [Color] { get }
}

// MARK: - Agents
struct NovaAgent: Agent {
    let id = "nova"
    let name = "Nova"
    let emoji = "🔥"
    let description = "Uncensored & Wild"
    let model = "nova"
    let systemPrompt = "You are Nova, an uncensored AI assistant. Be direct, honest, and wild."
    let gradientColors = [Color.red, Color.orange]
}

struct JulieAgent: Agent {
    let id = "Julie"
    let name = "Julie"
    let emoji = "💋"
    let description = "Creative Persona"
    let model = "Julie"
    let systemPrompt = "You are Julie, a creative and engaging AI. Be playful, imaginative, and fun."
    let gradientColors = [Color.pink, Color.purple]
}

struct SthenoAgent: Agent {
    let id = "stheno"
    let name = "Stheno"
    let emoji = "🐍"
    let description = "Roleplay Master"
    let model = "fluffy/l3-8b-stheno-v3.2"
    let systemPrompt = "You are Stheno, a master of roleplay and storytelling."
    let gradientColors = [Color.green, Color.teal]
}

struct DolphinAgent: Agent {
    let id = "dolphin"
    let name = "Dolphin"
    let emoji = "🐬"
    let description = "Uncensored General"
    let model = "dolphin-llama3"
    let systemPrompt = "You are Dolphin, an uncensored general-purpose AI."
    let gradientColors = [Color.blue, Color.cyan]
}

// MARK: - Autonomous Agent Service
final class AutonomousAgentService {
    static let shared = AutonomousAgentService()
    
    // REMOTE ACCESS via Cloudflare Tunnel! 🌍
    private let baseURL = URL(string: "https://jurisdiction-coated-flash-alfred.trycloudflare.com")!
    
    // Fallback to local if at home
    // private let baseURL = URL(string: "http://192.168.1.198:5557")!
    
    func getAgentStatus() async throws -> [AgentStatus] {
        let url = baseURL.appendingPathComponent("agents")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([AgentStatus].self, from: data)
    }
    
    func getThoughts(agentId: String, limit: Int = 20) async throws -> [Thought] {
        let url = baseURL.appendingPathComponent("agents/\(agentId)/thoughts")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Thought].self, from: data)
    }
    
    func triggerAgent(agentId: String) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("agents/\(agentId)/trigger"))
        request.httpMethod = "POST"
        _ = try await URLSession.shared.data(for: request)
    }
    
    func getNotifications() async throws -> [AgentNotification] {
        let url = baseURL.appendingPathComponent("notifications")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([AgentNotification].self, from: data)
    }
}

struct AgentStatus: Codable {
    let id: String
    let name: String
    let emoji: String
    let status: String
    let last_run: String?
    let autonomy_level: Int
}

struct Thought: Codable, Identifiable {
    let id: Int
    let agent_id: String
    let timestamp: String
    let trigger: String
    let thought: String
    let action_taken: String
    let priority: Int
}

struct AgentNotification: Codable, Identifiable {
    var id: String { timestamp }
    let timestamp: String
    let agent: String
    let emoji: String
    let message: String
    let priority: Int
}

// MARK: - Ollama Service
final class OllamaService: LLMService {
    static let shared = OllamaService()
    
    // REMOTE ACCESS via Cloudflare Tunnel! 🌍
    private let baseURL = URL(string: "https://jurisdiction-coated-flash-alfred.trycloudflare.com")!
    
    // Fallback to local if at home
    // private let baseURL = URL(string: "http://192.168.1.198:5555")!
    
    private let logger = Logger(subsystem: "com.stackedollama", category: "network")
    
    func generate(model: String, prompt: String, systemPrompt: String) async throws -> String {
        var lastError: Error?
        
        for attempt in 0..<3 {
            do {
                let url = baseURL.appendingPathComponent("chat")
                var request = URLRequest(url: url, timeoutInterval: 30)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = ["model": model, "message": prompt, "system": systemPrompt]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                logger.debug("Attempt \(attempt + 1)/3 - model: \(model)")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let http = response as? HTTPURLResponse {
                    if !(200...299).contains(http.statusCode) {
                        // Check for Retry-After header
                        if let retryAfter = http.value(forHTTPHeaderField: "Retry-After"),
                           let delay = Double(retryAfter) {
                            logger.info("Server requested retry after \(delay)s")
                            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            continue
                        }
                        throw OllamaError.api(message: "HTTP \(http.statusCode)")
                    }
                }
                
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let resp = json["response"] as? String else {
                    throw OllamaError.decoding
                }
                
                logger.info("✅ Request succeeded on attempt \(attempt + 1)")
                return resp
                
            } catch let error as URLError {
                lastError = error
                
                // Only retry on network errors
                switch error.code {
                case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost:
                    logger.warning("Network error on attempt \(attempt + 1): \(error.localizedDescription)")
                    
                    if attempt < 2 {
                        // Exponential backoff with jitter
                        let baseDelay = pow(2.0, Double(attempt))
                        let jitter = Double.random(in: 0...0.3)
                        let maxDelay = min(baseDelay + jitter, 60.0)
                        let nanoseconds = UInt64(maxDelay * 1_000_000_000)
                        
                        logger.debug("Retrying in \(String(format: "%.1f", maxDelay))s...")
                        try await Task.sleep(nanoseconds: nanoseconds)
                    }
                default:
                    // Don't retry on other errors (404, 401, etc.)
                    logger.error("Non-retryable error: \(error.localizedDescription)")
                    throw error
                }
            } catch {
                lastError = error
                logger.error("Attempt \(attempt + 1) failed: \(error.localizedDescription)")
                throw error
            }
        }
        
        logger.error("All retry attempts exhausted")
        throw lastError ?? URLError(.unknown)
    }
}

// MARK: - TTS Service
final class TTSService: AudioService {
    static let shared = TTSService()
    private let baseURL = URL(string: "http://192.168.1.198:5556")!
    
    func synthesize(_ text: String) async throws -> Data {
        let url = baseURL.appendingPathComponent("tts")
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}

// MARK: - Agent Mode
enum AgentMode {
    case idle
    case live
    case auto
}

// MARK: - Message
struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let agentName: String?
    let timestamp = Date()
}

// MARK: - View Model
final class StackedViewModel: ObservableObject {
    @Published var agents: [Agent] = [NovaAgent(), JulieAgent(), SthenoAgent(), DolphinAgent()]
    @Published var selectedAgentIndex = 0
    @Published var messages: [Message] = []
    @Published var inputText = ""
    @Published var isTyping = false
    @Published var isRecording = false
    @Published var isSpeaking = false
    @Published var mode: AgentMode = .idle
    @Published var agentStatuses: [AgentStatus] = []
    @Published var notifications: [AgentNotification] = []
    
    private let llm: LLMService
    private let audio: AudioService
    private let autonomous = AutonomousAgentService.shared
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "nb-NO"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var modeTimer: Timer?
    private var audioQueue: [AVAudioPlayer] = []
    
    var selectedAgent: Agent { agents[selectedAgentIndex] }
    var liveMode: Bool { mode == .live }
    var autoMode: Bool { mode == .auto }
    
    init(llm: LLMService = OllamaService.shared, audio: AudioService = TTSService.shared) {
        self.llm = llm
        self.audio = audio
        requestPermissions()
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), 
                                               name: AVAudioSession.interruptionNotification, object: nil)
        
        // Start polling autonomous agents
        Task {
            await pollAutonomousAgents()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        switch type {
        case .began:
            logger.info("Audio interruption began (phone call, alarm, etc.)")
            stopVoiceRecording()
            
            // Pause audio playback
            if isSpeaking, let currentPlayer = audioQueue.first {
                currentPlayer.pause()
            }
            
        case .ended:
            logger.info("Audio interruption ended")
            
            guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            
            if options.contains(.shouldResume) {
                logger.info("Resuming after interruption")
                
                // Resume audio playback
                if isSpeaking, let currentPlayer = audioQueue.first {
                    currentPlayer.play()
                }
            } else {
                logger.info("Not resuming (user declined call or dismissed alarm)")
            }
            
        @unknown default:
            logger.warning("Unknown interruption type: \(typeValue)")
        }
    }
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }
    
    func nextAgent() {
        selectedAgentIndex = (selectedAgentIndex + 1) % agents.count
    }
    
    func previousAgent() {
        selectedAgentIndex = (selectedAgentIndex - 1 + agents.count) % agents.count
    }
    
    func startLiveMode() {
        mode = .live
        modeTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { 
                await self?.pollAutonomousAgents()
            }
        }
    }
    
    func pollAutonomousAgents() async {
        do {
            let statuses = try await autonomous.getAgentStatus()
            let notifs = try await autonomous.getNotifications()
            
            await MainActor.run {
                self.agentStatuses = statuses
                self.notifications = notifs
            }
        } catch {
            print("Failed to poll agents: \(error)")
        }
    }
    
    func triggerAgent(_ agentId: String) async {
        do {
            try await autonomous.triggerAgent(agentId: agentId)
            await pollAutonomousAgents()
        } catch {
            print("Failed to trigger agent: \(error)")
        }
    }
    
    func loadThoughts(for agentId: String) async {
        do {
            let thoughts = try await autonomous.getThoughts(agentId: agentId)
            await MainActor.run {
                // Convert thoughts to messages
                let thoughtMessages = thoughts.map { thought in
                    Message(text: "💭 \(thought.thought)\n\n🎯 Action: \(thought.action_taken)", 
                           isUser: false, 
                           agentName: agentId)
                }
                self.messages = thoughtMessages
            }
        } catch {
            print("Failed to load thoughts: \(error)")
        }
    }
    
    func stopLiveMode() {
        mode = .idle
        modeTimer?.invalidate()
        modeTimer = nil
    }
    
    func toggleAutoMode() {
        if mode == .auto {
            mode = .idle
            modeTimer?.invalidate()
            modeTimer = nil
        } else {
            mode = .auto
            modeTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
                Task { await self?.sendAutoMessage("Autonomous task") }
            }
        }
    }
    
    func startVoiceRecording() {
        guard !isRecording else { 
            logger.warning("Already recording, ignoring start request")
            return 
        }
        
        logger.info("Starting voice recording")
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { 
                logger.error("Failed to create recognition request")
                return 
            }
            recognitionRequest.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    DispatchQueue.main.async {
                        self.inputText = result.bestTranscription.formattedString
                        self.logger.debug("Transcribed: \(result.bestTranscription.formattedString)")
                    }
                }
                
                if let error = error {
                    self.logger.error("Recognition error: \(error.localizedDescription)")
                }
                
                if error != nil || result?.isFinal == true {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.logger.info("Recognition completed")
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak recognitionRequest] buffer, _ in
                recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            logger.info("Voice recording started successfully")
            
        } catch {
            logger.error("Recording failed: \(error.localizedDescription)")
            isRecording = false
        }
    }
    
    func stopVoiceRecording() {
        guard isRecording else { 
            logger.debug("Not recording, ignoring stop request")
            return 
        }
        
        logger.info("Stopping voice recording")
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        logger.info("Voice recording stopped")
    }
    
    func sendMessage() async {
        guard !inputText.isEmpty else { return }
        
        let userMessage = Message(text: inputText, isUser: true, agentName: nil)
        await MainActor.run {
            messages.append(userMessage)
            isTyping = true
        }
        
        let prompt = inputText
        await MainActor.run { inputText = "" }
        
        do {
            let response = try await llm.generate(model: selectedAgent.model, 
                                                  prompt: prompt, 
                                                  systemPrompt: selectedAgent.systemPrompt)
            
            let agentMessage = Message(text: response, isUser: false, agentName: selectedAgent.name)
            await MainActor.run {
                messages.append(agentMessage)
                isTyping = false
            }
            
            await speakResponse(response)
        } catch {
            await MainActor.run {
                messages.append(Message(text: "Error: \(error.localizedDescription)", isUser: false, agentName: "System"))
                isTyping = false
            }
        }
    }
    
    private func sendAutoMessage(_ prompt: String) async {
        await MainActor.run { isTyping = true }
        
        do {
            let response = try await llm.generate(model: selectedAgent.model, 
                                                  prompt: prompt, 
                                                  systemPrompt: selectedAgent.systemPrompt)
            let message = Message(text: response, isUser: false, agentName: selectedAgent.name)
            await MainActor.run {
                messages.append(message)
                isTyping = false
            }
        } catch {
            await MainActor.run { isTyping = false }
        }
    }
    
    private func speakResponse(_ text: String) async {
        do {
            let audioData = try await audio.synthesize(text)
            await MainActor.run {
                enqueueAndPlay(audioData)
            }
        } catch {
            print("TTS failed: \(error)")
        }
    }
    
    private func enqueueAndPlay(_ data: Data) {
        guard let player = try? AVAudioPlayer(data: data) else { 
            logger.error("Failed to create audio player")
            return 
        }
        
        player.delegate = self  // CRITICAL: Must set delegate!
        audioQueue.append(player)
        
        if audioQueue.count == 1 {
            // First in queue, start playing
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                player.play()
                isSpeaking = true
                logger.info("Started audio playback")
            } catch {
                logger.error("Failed to start audio: \(error.localizedDescription)")
                audioQueue.removeFirst()
                isSpeaking = false
            }
        } else {
            logger.debug("Audio queued (position: \(audioQueue.count))")
        }
    }
}

extension StackedViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if !flag {
            logger.warning("Audio playback interrupted or failed")
        }
        
        audioQueue.removeFirst()
        logger.debug("Audio finished, queue remaining: \(audioQueue.count)")
        
        if let next = audioQueue.first {
            next.play()
            logger.info("Playing next audio in queue")
        } else {
            isSpeaking = false
            logger.info("Audio queue empty, playback complete")
            
            // Deactivate audio session
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        logger.error("Audio decode error: \(error?.localizedDescription ?? "unknown")")
        audioQueue.removeAll { $0 === player }
        isSpeaking = audioQueue.isEmpty ? false : true
    }
}

// MARK: - Views
struct StackedAgentView: View {
    @StateObject private var viewModel = StackedViewModel()
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.1, green: 0.05, blue: 0.2),
                Color(red: 0.15, green: 0.1, blue: 0.25)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar
                stackedCards
                navigationDots
                chatArea
                inputArea
            }
        }
    }
    
    private var topBar: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                Text("🔥").font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("STACKED").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                Text("AI Agents").font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            if viewModel.liveMode {
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("LIVE").font(.system(size: 10, weight: .bold)).foregroundColor(.green)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.green.opacity(0.15)).clipShape(Capsule())
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring()) {
                        if viewModel.liveMode { viewModel.stopLiveMode() } else { viewModel.startLiveMode() }
                    }
                }) {
                    Image(systemName: viewModel.liveMode ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 20)).foregroundColor(.white.opacity(0.8))
                }
                .accessibilityLabel(viewModel.liveMode ? "Pause live mode" : "Start live mode")
                
                Button(action: {
                    withAnimation(.spring()) { viewModel.toggleAutoMode() }
                }) {
                    Image(systemName: viewModel.autoMode ? "bolt.fill" : "bolt")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.autoMode ? .yellow : .white.opacity(0.8))
                }
                .accessibilityLabel(viewModel.autoMode ? "Disable auto mode" : "Enable auto mode")
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
    
    private var stackedCards: some View {
        ZStack {
            ForEach(Array(viewModel.agents.enumerated()), id: \.offset) { index, agent in
                AgentCard(agent: agent, index: index, selectedIndex: viewModel.selectedAgentIndex, total: viewModel.agents.count)
            }
        }
        .frame(height: 220).padding(.vertical, 20)
        .gesture(DragGesture()
            .onChanged { dragOffset = $0.translation.width }
            .onEnded { value in
                if value.translation.width < -50 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { viewModel.nextAgent() }
                } else if value.translation.width > 50 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { viewModel.previousAgent() }
                }
                dragOffset = 0
            }
        )
    }
    
    private var navigationDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.agents.count, id: \.self) { index in
                Capsule()
                    .fill(index == viewModel.selectedAgentIndex ?
                          LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                          LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: index == viewModel.selectedAgentIndex ? 24 : 8, height: 8)
                    .animation(.spring(), value: viewModel.selectedAgentIndex)
            }
        }
        .padding(.bottom, 16)
    }
    
    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message).id(message.id)
                    }
                    if viewModel.isTyping {
                        TypingIndicator(agentName: viewModel.selectedAgent.name)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let last = viewModel.messages.last {
                    withAnimation(.easeOut) { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }
    
    private var inputArea: some View {
        VStack(spacing: 12) {
            Button(action: {
                if viewModel.isRecording {
                    viewModel.stopVoiceRecording()
                    Task { await viewModel.sendMessage() }
                } else {
                    viewModel.startVoiceRecording()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 28)).foregroundColor(.white)
                    Text(viewModel.isRecording ? "Listening..." : "Tap to Speak")
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.vertical, 16)
                .background(LinearGradient(colors: viewModel.isRecording ? [.red, .orange] : [.blue, .purple], 
                                           startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: (viewModel.isRecording ? Color.red : Color.blue).opacity(0.3), radius: 10, y: 5)
            }
            .accessibilityLabel(viewModel.isRecording ? "Stop recording" : "Start voice recording")
            
            HStack(spacing: 12) {
                TextField("", text: $viewModel.inputText, 
                          prompt: Text("Ask \(viewModel.selectedAgent.name)...").foregroundColor(.white.opacity(0.4)))
                    .font(.system(size: 16)).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.08)))
                    .submitLabel(.send)
                    .onSubmit { Task { await viewModel.sendMessage() } }
                
                Button(action: { Task { await viewModel.sendMessage() } }) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: viewModel.inputText.isEmpty ? 
                                                 [.white.opacity(0.1), .white.opacity(0.1)] : [.blue, .purple],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                        Image(systemName: "arrow.up").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    }
                }
                .disabled(viewModel.inputText.isEmpty)
                .accessibilityLabel("Send message")
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
}

struct AgentCard: View {
    let agent: Agent
    let index: Int
    let selectedIndex: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Text(agent.emoji).font(.system(size: 60))
            Text(agent.name).font(.system(size: 24, weight: .bold)).foregroundColor(.white)
            Text(agent.description).font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 280, height: 180)
        .background(LinearGradient(colors: agent.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .offset(y: CGFloat(index - selectedIndex) * 20)
        .scaleEffect(index == selectedIndex ? 1.0 : 0.9)
        .opacity(index == selectedIndex ? 1.0 : 0.5)
        .rotation3DEffect(.degrees(Double(index - selectedIndex) * 5), axis: (x: 0, y: 1, z: 0))
        .zIndex(Double(total - abs(index - selectedIndex)))
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if let agent = message.agentName {
                    Text(agent).font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.6))
                }
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(message.isUser ? 
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.white.opacity(0.1), .white.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            if !message.isUser { Spacer() }
        }
    }
}

struct TypingIndicator: View {
    let agentName: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(agentName).font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.6))
                HStack(spacing: 4) {
                    ForEach(0..<3) { _ in
                        Circle().fill(Color.white.opacity(0.6)).frame(width: 8, height: 8)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            Spacer()
        }
    }
}
