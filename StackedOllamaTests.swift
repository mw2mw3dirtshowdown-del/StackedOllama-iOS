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
