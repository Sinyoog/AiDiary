import Foundation
import Combine

class DiaryAnalyzer: ObservableObject {
    private let geminiService = GeminiService()
    
    @Published var summary: String?
    @Published var emotion: String?
    @Published var solution: String?
    @Published var errorMessage: String?
    
    private var debounceWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 1.5
    private var lastCallTime: Date?
    private let minIntervalBetweenCalls: TimeInterval = 5.0
    
    func analyze(text: String) {
        guard text.count > 10 else {
            errorMessage = "내용이 너무 짧아요."
            clearResults()
            return
        }
        
        debounceWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.tryCallAPI(text)
        }
        debounceWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
    
    private func tryCallAPI(_ text: String) {
        let now = Date()
        if let last = lastCallTime, now.timeIntervalSince(last) < minIntervalBetweenCalls {
            errorMessage = "잠시 후 다시 시도해주세요."
            return
        }
        
        lastCallTime = now
        errorMessage = nil
        
        geminiService.analyzeDiaryText(text) { [weak self] summary, emotion, solution, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "분석 실패: \(error.localizedDescription)"
                    self?.clearResults()
                } else {
                    self?.summary = summary
                    self?.emotion = emotion
                    self?.solution = solution
                }
            }
        }
    }
    
    private func clearResults() {
        summary = nil
        emotion = nil
        solution = nil
    }
}
