import Foundation
import CoreData

class DiaryViewModel: ObservableObject {
    // SwiftUI View에서 .environment(\.managedObjectContext, ...)로 넘긴 context 사용
    func addDiaryEntry(
        context: NSManagedObjectContext,
        title: String,
        content: String,
        emotion: String? = nil,
        summary: String? = nil,
        solution: String? = nil,
        isSevere: Bool = false
    ) {
        let newEntry = DiaryEntry(context: context)
        newEntry.id = UUID()
        newEntry.date = Date()
        newEntry.title = title
        newEntry.content = content
        newEntry.emotion = emotion
        newEntry.summary = summary
        newEntry.solution = solution
        newEntry.isSevere = isSevere

        do {
            try context.save()
        } catch {
            print("Error saving new diary entry: \(error)")
        }
    }
}
