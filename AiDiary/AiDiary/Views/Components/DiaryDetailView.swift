import SwiftUI
import CoreData

struct DiaryDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) var presentationMode
    
    var diaryEntry: DiaryEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text("제목: \(diaryEntry.title ?? "그날 일기입니다.")")
                    .font(.title2)
                    .bold()

                if let date = diaryEntry.date {
                    Text(date, style: .date)
                        .foregroundColor(.secondary)
                }

                Divider()

                Text(diaryEntry.content ?? "")
                    .font(.body)

                Divider()

                if let summary = diaryEntry.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("일기 내용")
                            .font(.headline)
                        Text(summary)
                            .font(.body)
                    }
                }

                if let emotion = diaryEntry.emotion, !emotion.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("감정")
                            .font(.headline)
                        Text(emotion)
                            .font(.body)
                    }
                }

                if let solution = diaryEntry.solution, !solution.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("해결책")
                            .font(.headline)
                        Text(solution)
                            .font(.body)
                    }
                }

                Spacer()

                Button(role: .destructive) {
                    context.delete(diaryEntry)
                    do {
                        try context.save()
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        print("삭제 실패: \(error)")
                    }
                } label: {
                    Text("일기 삭제")
                        .foregroundColor(.red)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("일기 상세")
        .navigationBarBackButtonHidden(false)
    }
}
