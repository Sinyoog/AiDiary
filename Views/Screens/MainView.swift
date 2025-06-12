import SwiftUI
import CoreData

struct MainView: View {
    @Environment(\.managedObjectContext) private var context

    @State private var currentMonth: Date = {
        let now = Date()
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
    }()

    @State private var selectedDate = Date()

    enum ActiveSheet: Identifiable {
        case writeDiary, showSettings
        
        var id: Int { hashValue }
    }
    
    @State private var activeSheet: ActiveSheet?
    @State private var analyzedEntry: DiaryEntry?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DiaryEntry.date, ascending: true)],
        animation: .default)
    private var diaryEntries: FetchedResults<DiaryEntry>

    private var calendar = Calendar.current
    private let weekDays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        var dates: [Date] = []
        var current = monthInterval.start
        while current < monthInterval.end {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }

    private func entryForSelectedDate() -> DiaryEntry? {
        diaryEntries.first(where: {
            guard let date = $0.date else { return false }
            return Calendar.current.isDate(date, inSameDayAs: selectedDate)
        })
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // 캘린더 영역
                VStack(spacing: 10) {
                    HStack {
                        Button("<") { changeMonth(by: -1) }
                        Spacer()
                        Text(monthYearString(currentMonth))
                            .font(.headline)
                        Spacer()
                        Button(">") { changeMonth(by: 1) }
                    }
                    .padding(.horizontal)

                    HStack {
                        ForEach(weekDays, id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    let firstWeekday = calendar.component(.weekday, from: daysInMonth.first ?? Date())
                    let offset = firstWeekday - calendar.firstWeekday
                    let totalSquares = daysInMonth.count + offset

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 15) {
                        ForEach(0..<totalSquares, id: \.self) { i in
                            if i < offset {
                                Color.clear.frame(height: 50)
                            } else {
                                let date = daysInMonth[i - offset]
                                dayView(date: date)
                                    .frame(height: 50)
                                    .onTapGesture { selectedDate = date }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: .infinity)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)

                // 일기 보기 영역
                if let entry = entryForSelectedDate() {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("제목 : \(entry.title ?? formattedDateTitle(for: selectedDate))")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        NavigationLink(destination: DiaryDetailView(diaryEntry: entry)
                            .environment(\.managedObjectContext, context)) {
                            Text("일기 보기")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    Text("선택한 날짜에 작성된 일기가 없습니다.")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                Spacer()

                Button("일기 쓰기") {
                    guard entryForSelectedDate() == nil else { return }
                    activeSheet = .writeDiary
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    entryForSelectedDate() == nil ? Color.blue : Color.gray
                )
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 20)
                .disabled(entryForSelectedDate() != nil)
            }
            .navigationTitle("AiDiary")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        activeSheet = .showSettings
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 33))  // 두 배 크기 설정
                    }
                }
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .writeDiary:
                    DiaryWriteView(
                        selectedDate: selectedDate,
                        existingEntry: entryForSelectedDate(),
                        activeSheet: $activeSheet,
                        analyzedEntry: $analyzedEntry
                    )
                    .environment(\.managedObjectContext, context)

                case .showSettings:
                    SettingsView(showSettings: Binding(
                        get: { activeSheet == .showSettings },
                        set: { if !$0 { activeSheet = nil } }
                    ))
                }
            }
        }
    }

    private func formattedDateTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")  // 한국어 로케일
        formatter.dateFormat = "M월 d일"
        return "\(formatter.string(from: date)) 일기입니다."
    }

    private func dayView(date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        return Text("\(calendar.component(.day, from: date))")
            .frame(maxWidth: .infinity, maxHeight: 50)
            .background(isSelected ? Color.blue : Color.clear)
            .foregroundColor(isSelected ? .white : isToday ? .red : .primary)
            .clipShape(Circle())
    }

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) else { return }
        currentMonth = newMonth
    }
}
