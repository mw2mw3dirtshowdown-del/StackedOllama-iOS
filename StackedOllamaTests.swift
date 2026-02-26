import XCTest
@testable import StackedOllama

final class StackedOllamaTests: XCTestCase {
    func testAgentsExist() {
        let viewModel = StackedViewModel()
        XCTAssertEqual(viewModel.agents.count, 4)
        XCTAssertEqual(viewModel.agents[0].name, "Nova")
        XCTAssertEqual(viewModel.agents[1].name, "Julie")
        XCTAssertEqual(viewModel.agents[2].name, "Stheno")
        XCTAssertEqual(viewModel.agents[3].name, "Dolphin")
    }
    
    func testAgentSelection() {
        let viewModel = StackedViewModel()
        XCTAssertEqual(viewModel.selectedAgentIndex, 0)
        
        viewModel.nextAgent()
        XCTAssertEqual(viewModel.selectedAgentIndex, 1)
        
        viewModel.previousAgent()
        XCTAssertEqual(viewModel.selectedAgentIndex, 0)
    }
    
    func testOllamaServiceExists() {
        let service = OllamaService.shared
        XCTAssertNotNil(service)
    }
}

// MARK: - Mocks for Testing
class MockLLMService: LLMService {
    func generate(model: String, prompt: String, systemPrompt: String) async throws -> String {
        return "Mock AI response for testing"
    }
    
    func stream(model: String, prompt: String, systemPrompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield("Mock")
            continuation.yield(" streaming")
            continuation.yield(" response")
            continuation.finish()
        }
    }
}

class MockTTSService: AudioService {
    func synthesize(_ text: String) async throws -> Data {
        return Data("mock audio data".utf8) // Mock audio data
    }
}

// MARK: - Integration Tests
extension StackedOllamaTests {
    func testSendMessageWithMocks() async {
        let mockLLM = MockLLMService()
        let mockTTS = MockTTSService()
        let viewModel = StackedViewModel(llm: mockLLM, audio: mockTTS)
        
        // Set up test message
        viewModel.inputText = "Hello AI"
        
        // Send message
        await viewModel.sendMessage()
        
        // Verify results
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages[0].text, "Hello AI")
        XCTAssertEqual(viewModel.messages[0].isUser, true)
        XCTAssertEqual(viewModel.messages[1].text, "Mock streaming response")
        XCTAssertEqual(viewModel.messages[1].isUser, false)
        XCTAssertEqual(viewModel.messages[1].agentName, "Nova")
        XCTAssertFalse(viewModel.isTyping)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testModeToggle() {
        let viewModel = StackedViewModel()
        
        // Start live mode
        viewModel.startLiveMode()
        XCTAssertEqual(viewModel.mode, .live)
        
        // Stop live mode
        viewModel.stopLiveMode()
        XCTAssertEqual(viewModel.mode, .idle)
        
        // Toggle auto mode
        viewModel.toggleAutoMode()
        XCTAssertEqual(viewModel.mode, .auto)
        
        // Toggle back to idle
        viewModel.toggleAutoMode()
        XCTAssertEqual(viewModel.mode, .idle)
    }
}
