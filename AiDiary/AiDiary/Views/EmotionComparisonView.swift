import SwiftUI
import CoreData

struct EmotionComparisonView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    enum Period {
        case week, month
    }

    let emotionScores: [String: Int] = [
        // --- 매우 긍정적 (4점) ---
        "환희": 4, "행복": 4, "기쁨": 4, "즐거움": 4, "희열": 4, "황홀경": 4, "사랑": 4, "감격": 4,
        "벅참": 4, "심쿵": 4, "최고": 4, "환상적": 4, "극치": 4, "승리감": 4, "경외심": 4,

        // --- 긍정적 (3점) ---
        "만족": 3, "뿌듯함": 3, "감사": 3, "안도": 3, "설렘": 3, "평화로움": 3, "편안함": 3,
        "자부심": 3, "희망": 3, "기대": 3, "흥분": 3, "용기": 3, "활기참": 3, "신남": 3,
        "개운함": 3, "긍정적": 3, "생기": 3, "활력": 3, "든든함": 3, "온화함": 3, "따뜻함": 3,
        "충족감": 3, "흡족함": 3, "흐뭇함": 3, "평화": 3, "흥미진진": 3, "홀가분함": 3,

        // --- 약간 긍정적 (2점) ---
        "좋음": 2, "가벼움": 2, "포근함": 2, "상쾌함": 2, "희망적": 2, "산뜻함": 2,
        "괜찮음": 2, "무난함": 2, "명랑함": 2, "유쾌함": 2, "쾌활함": 2, "차분함": 2,
        "여유로움": 2, "개운하다": 2, "기분좋음": 2, "호감": 2, "흥미로움": 2,

        // --- 미묘/중립 (1점 ~ 0점) ---
        "신중함": 1, "관심": 1, "덤덤함": 1, "경계심": 1, "호기심": 1,
        "중립": 0, "무감정": 0, "보통": 0, "무관심": 0, "냉정": 0, "담담함": 0,
        "익숙함": 0, "별 감정 없음": 0, "무미건조": 0, "미적지근함": 0, "관심 없음": 0,

        // --- 약간 부정적 (-1점) ---
        "걱정": -1, "긴장": -1, "당황": -1, "피곤": -1, "지침": -1, "미묘함": -1, "심심함": -1,
        "무료함": -1, "멍함": -1, "정신 없음": -1, "혼란": -1, "어색함": -1, "부끄러움": -1,
        "민망함": -1, "어리둥절": -1, "귀찮음": -1, "피로감": -1, "허기짐": -1, "찝찝함": -1,
        "어정쩡함": -1, "애매함": -1, "망설임": -1, "조바심": -1, "씁쓸함": -1,
        "두근거림(부정)": -1, "난감함": -1, "조심스러움": -1, "답답함": -1,

        // --- 부정적 (-2점) ---
        "불안": -2, "초조": -2, "실망": -2, "외로움": -2, "서운함": -2, "후회": -2, "죄책감": -2,
        "지루함": -2, "권태": -2, "공허함": -2, "허무함": -2, "무의미함": -2, "의욕 없음": -2,
        "의욕 상실": -2, "무력감": -2, "허탈함": -2, "공백감": -2, "불만": -2, "억울": -2,
        "혼돈": -2, "불확실": -2, "걱정스러움": -2, "짜증남": -2, "불쾌함": -2, "속상함": -2,
        "우울함": -2, "복잡함": -2, "뒤숭숭함": -2, "먹먹함": -2, "부담감": -2,
        "불안감": -2, "불신": -2, "좌절": -2, "체념": -2, "울적함": -2, "피곤함": -2,

        // --- 매우 부정적 (-3점) ---
        "슬픔": -3, "우울": -3, "짜증": -3, "분노": -3, "불행": -3, "상처": -3, "비참": -3,
        "무기력감": -3, "고통": -3, "억울함": -3, "열등감": -3, "시기심": -3, "부러움": -3,
        "실망스러움": -3, "상실감": -3, "괴로움": -3, "곤혹스러움": -3, "억압": -3, "굴욕": -3,
        "창피함": -3, "초라함": -3, "쓸쓸함": -3, "소외감": -3, "고립감": -3, "괴리감": -3,
        "불화": -3, "미움": -3, "비애감": -3, "침울함": -3, "음울함": -3, "한숨": -3,

        // --- 극단적 부정적 (-4점) ---
        "절망": -4, "절망감": -4, "공포": -4, "두려움": -4, "혐오": -4, "증오": -4, "극심한 분노": -4,
        "치욕": -4, "수치심": -4, "비통함": -4, "고독": -4, "죽고 싶음": -4, "견딜 수 없음": -4,
        "모든 게 싫음": -4, "공포심": -4, "병든": -4, "위협적": -4, "불안정": -4, "피로누적": -4,
        "소름끼침": -4, "오싹함": -4, "섬뜩함": -4, "자살충동": -4, "악몽같음": -4
    ]
    
    let gradientColors: [Color] = [
        Color.blue, Color.blue.opacity(0.8), Color.blue.opacity(0.6),
        Color.purple.opacity(0.6),Color.purple,Color.purple.opacity(0.8),
        Color.red.opacity(0.8), Color.red.opacity(0.9), Color.red, Color.red
    ]

    let emotionLabels = [
        "매우 부정적", "부정적", "약간 부정적", "조금 부정적", "중립",
        "조금 긍정적", "긍정적", "아주 긍정적", "기쁨", "매우 기쁨"
    ]

    @State private var weeklyAverage: Double = 0
    @State private var monthlyAverage: Double = 0
    @State private var weeklyCount: Int = 0
    @State private var monthlyCount: Int = 0

    @State private var selectedDetailPeriod: Period? = nil
    @State private var weeklyDailyScores: [(Date, Double)] = []
    @State private var monthlyDailyScores: [(Date, Double)] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("감정 비교")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)

                    // 1주일
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("최근 1주일 감정 평균 점수:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.2f", weeklyAverage))
                                    .font(.headline)
                            }
                            Spacer()
                            Button("1주일 감정 변화 보기") {
                                toggleDetail(.week)
                            }
                        }

                        colorBarView(average: weeklyAverage)
                        emojiIndicator(average: weeklyAverage)

                        Text(emotionLabel(for: weeklyAverage))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("분석된 일기 개수: \(weeklyCount)개")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if selectedDetailPeriod == .week {
                            emotionLineChart(scores: weeklyDailyScores, days: 7, showAllDates: true)
                                .frame(height: 200)
                                .padding(.top)
                        }
                    }

                    Divider()

                    // 1개월
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("최근 1개월 감정 평균 점수:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.2f", monthlyAverage))
                                    .font(.headline)
                            }
                            Spacer()
                            Button("1개월 감정 변화 보기") {
                                toggleDetail(.month)
                            }
                        }

                        colorBarView(average: monthlyAverage)
                        emojiIndicator(average: monthlyAverage)

                        Text(emotionLabel(for: monthlyAverage))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("분석된 일기 개수: \(monthlyCount)개")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if selectedDetailPeriod == .month {
                            emotionLineChart(scores: monthlyDailyScores, days: 30, showAllDates: false)
                                .frame(height: 200)
                                .padding(.top)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(leading: Button("닫기") { dismiss() })
        }
        .onAppear(perform: loadEmotionData)
    }

    private func toggleDetail(_ period: Period) {
        if selectedDetailPeriod == period {
            selectedDetailPeriod = nil
        } else {
            selectedDetailPeriod = period
        }
    }

    private func scoreToIndex(_ score: Double) -> Int {
        let shifted = score + 3
        let idx = Int(round(shifted / 6 * 9))
        return min(max(idx, 0), 9)
    }

    private func emotionLabel(for score: Double) -> String {
        let idx = scoreToIndex(score)
        return emotionLabels[idx]
    }

    @ViewBuilder
    private func colorBarView(average: Double) -> some View {
        let currentIndex = scoreToIndex(average)

        HStack(spacing: 4) {
            ForEach(0..<10) { idx in
                Rectangle()
                    .fill(gradientColors[idx])
                    .frame(height: 20)
                    .overlay(
                        idx == currentIndex ? Text("🙂").offset(y: -25) : nil
                    )
                    .cornerRadius(4)
            }
        }
    }

    @ViewBuilder
    private func emojiIndicator(average: Double) -> some View {
        let idx = scoreToIndex(average)
        let color = gradientColors[idx]

        GeometryReader { geo in
            let width = geo.size.width
            let ratio = (average + 4) / 8  // 점수 -4~+4 → 0.0~1.0 정규화
            let xPosition = width * ratio

            Text("🙂")
                .font(.largeTitle)
                .foregroundColor(color)
                .position(x: xPosition, y: 20)
                .animation(.easeInOut(duration: 0.3), value: xPosition)
        }
        .frame(height: 40)
    }

    private func emotionLineChart(scores: [(Date, Double)], days: Int, showAllDates: Bool) -> some View {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -days + 1, to: now)!)

        let allDates: [Date] = (0..<days).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startDate)
        }

        var dailyScoresDict: [Date: Double] = [:]
        for (date, score) in scores {
            let day = calendar.startOfDay(for: date)
            dailyScoresDict[day] = score
        }

        let dailyScores: [Double] = allDates.map { dailyScoresDict[$0] ?? 0 }

        return VStack(spacing: 8) {
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
                let maxScore = 4.0
                let midY = height / 2

                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 2)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(10)

                    // 중앙 중립선 (보라색)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: midY))
                        path.addLine(to: CGPoint(x: width, y: midY))
                    }
                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 1))

                    // 감정 그래프 라인 (빨강/파랑)
                    Path { path in
                        for i in 0..<dailyScores.count-1 {
                            let y1 = midY - CGFloat(dailyScores[i] / maxScore) * (midY * 0.9)
                            let y2 = midY - CGFloat(dailyScores[i+1] / maxScore) * (midY * 0.9)
                            let x1 = CGFloat(i) * (width / CGFloat(dailyScores.count - 1))
                            let x2 = CGFloat(i+1) * (width / CGFloat(dailyScores.count - 1))

                            let color1 = dailyScores[i] >= 0 ? Color.red : Color.blue
                            let color2 = dailyScores[i+1] >= 0 ? Color.red : Color.blue

                            if color1 == color2 {
                                path.move(to: CGPoint(x: x1, y: y1))
                                path.addLine(to: CGPoint(x: x2, y: y2))
                            } else {
                                // 색이 바뀌면 중간에서 분리
                                let midX = (x1 + x2) / 2
                                let midYValue = (y1 + y2) / 2

                                path.move(to: CGPoint(x: x1, y: y1))
                                path.addLine(to: CGPoint(x: midX, y: midYValue))

                                path.move(to: CGPoint(x: midX, y: midYValue))
                                path.addLine(to: CGPoint(x: x2, y: y2))
                            }
                        }
                    }
                    .stroke(Color.black, lineWidth: 1) // 실제 그리기 할 때는 아래에서 색 변경

                    // 점 표시
                    ForEach(0..<dailyScores.count, id: \.self) { i in
                        let yValue = dailyScores[i]
                        let normalized = yValue / maxScore
                        let y = midY - CGFloat(normalized) * (midY * 0.9)
                        let x = CGFloat(i) * (width / CGFloat(dailyScores.count - 1))

                        let pointColor: Color = yValue == 0 ? .black : (yValue > 0 ? .red : .blue)

                        Circle()
                            .fill(pointColor)
                            .frame(width: 5, height: 5)
                            .position(x: x, y: y)
                    }
                }
            }
            .frame(height: 200)

            HStack {
                if showAllDates {
                    ForEach(allDates, id: \.self) { date in
                        Text("\(calendar.component(.month, from: date))/\(calendar.component(.day, from: date))")
                            .font(.caption2)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    Text("\(calendar.component(.month, from: allDates.first!))/\(calendar.component(.day, from: allDates.first!))")
                        .font(.caption2)
                    Spacer()
                    Text("\(calendar.component(.month, from: allDates.last!))/\(calendar.component(.day, from: allDates.last!))")
                        .font(.caption2)
                }
            }
        }
    }

    private func loadEmotionData() {
        let now = Date()
        let calendar = Calendar.current

        let weekAgo = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -6, to: now)!)
        let monthAgo = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -29, to: now)!)

        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND emotion != nil AND emotion != ''", monthAgo as NSDate)

        do {
            let entries = try context.fetch(request)

            let monthEntries = entries.filter {
                if let date = $0.date {
                    return date >= monthAgo && date <= now
                }
                return false
            }

            let weekEntries = monthEntries.filter {
                if let date = $0.date {
                    return date >= weekAgo && date <= now
                }
                return false
            }

            func averageEmotionScore(_ entries: [DiaryEntry]) -> Double {
                var totalScore = 0
                var totalCount = 0

                for entry in entries {
                    guard let emotion = entry.emotion else { continue }
                    let components = emotion
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

                    for e in components {
                        if let score = emotionScores[e] {
                            totalScore += score
                            totalCount += 1
                        }
                    }
                }

                guard totalCount > 0 else { return 0 }
                return Double(totalScore) / Double(totalCount)
            }


            func dailyEmotionScores(_ entries: [DiaryEntry]) -> [(Date, Double)] {
                var dailyDict: [Date: [Int]] = [:]
                for entry in entries {
                    if let date = entry.date, let emotion = entry.emotion {
                        let day = calendar.startOfDay(for: date)
                        let components = emotion.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        let scores = components.compactMap { emotionScores[$0] }

                        if !scores.isEmpty {
                            dailyDict[day, default: []].append(contentsOf: scores)
                        }
                    }
                }

                return dailyDict.map { (key, scores) in
                    let avg = Double(scores.reduce(0, +)) / Double(scores.count)
                    return (key, avg)
                }
                .sorted { $0.0 < $1.0 }
            }


            weeklyAverage = averageEmotionScore(weekEntries)
            monthlyAverage = averageEmotionScore(monthEntries)
            weeklyCount = weekEntries.count
            monthlyCount = monthEntries.count

            weeklyDailyScores = dailyEmotionScores(weekEntries)
            monthlyDailyScores = dailyEmotionScores(monthEntries)

        } catch {
            print("감정 데이터 로드 실패: \(error.localizedDescription)")
            weeklyAverage = 0
            monthlyAverage = 0
            weeklyCount = 0
            monthlyCount = 0
            weeklyDailyScores = []
            monthlyDailyScores = []
        }
    }
}
