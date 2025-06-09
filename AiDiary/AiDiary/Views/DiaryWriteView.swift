import SwiftUI
import CoreData

struct DiaryWriteView: View {
    var selectedDate: Date
    var existingEntry: DiaryEntry?
    @Environment(\.managedObjectContext) var context
    
    @State private var title: String = ""
    @State private var content: String = ""
    
    private let geminiService = GeminiService()
    @State private var isSaving = false
    
    @Binding var activeSheet: MainView.ActiveSheet?
    @Binding var analyzedEntry: DiaryEntry?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("제목 입력", text: $title)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                TextEditor(text: $content)
                    .frame(minHeight: 150)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                Button(isSaving ? "분석 중..." : "분석") {
                    analyzeDiary()
                }
                .disabled(isSaving)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSaving ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
            .navigationBarTitle("일기 쓰기", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                activeSheet = nil
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            })
            .onAppear {
                if let existing = existingEntry {
                    title = existing.title ?? ""
                    content = existing.content ?? ""
                }
            }
        }
    }
    
    private func formattedDateTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return "\(formatter.string(from: date)) 일기입니다."
    }

    private func analyzeDiary() {
        guard !content.isEmpty else {
            print("분석 실패: 내용이 비어있음")
            return
        }
        
        print("GPT 요청 보내는 텍스트 길이: \(content.count)")
        
        isSaving = true
        
        geminiService.analyzeDiaryText(content) { summary, emotion, solution, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("GPT 분석 실패: \(error.localizedDescription)")
                    isSaving = false
                    return
                }
                
                print("GPT 응답 summary: \(summary ?? "nil")")
                print("GPT 응답 emotion: \(emotion ?? "nil")")
                print("GPT 응답 solution: \(solution ?? "nil")")
                
                let entry = existingEntry ?? DiaryEntry(context: context)
                entry.title = title.isEmpty ? formattedDateTitle(for: selectedDate) : title
                entry.content = content
                entry.date = selectedDate
                if existingEntry == nil {
                    entry.id = UUID()
                }
                entry.summary = summary
                entry.emotion = emotion
                entry.solution = solution
                
                do {
                    try context.save()
                    print("저장 완료, 일기 제목: \(entry.title ?? "없음")")
                    analyzedEntry = entry
                    isSaving = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        activeSheet = nil
                    }
                } catch {
                    print("저장 실패: \(error)")
                    isSaving = false
                }
            }
        }
    }
}
