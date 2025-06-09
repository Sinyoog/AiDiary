import Foundation

class GeminiService {
    
    private var apiKey: String? {
        let key = Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey") as? String
        print("✅ Info.plist에서 불러온 Gemini API 키: \(key ?? "nil")")
        return key
    }

    private let maxRetryCount = 5

    typealias AnalyzeCompletion = (_ summary: String?, _ emotion: String?, _ solution: String?, _ error: Error?) -> Void

    private let allowedEmotions: Set<String> = [
        "환희", "행복", "기쁨", "즐거움", "희열", "황홀경", "사랑", "감격", "벅참", "심쿵",
        "만족", "뿌듯함", "감사", "안도", "설렘", "평화로움", "편안함", "자부심", "희망", "기대",
        "흥분", "용기", "활기참", "신남", "만족스러움", "개운함",
        "좋음", "긍정", "가벼움", "흥미", "호기심", "포근함", "따뜻함", "상쾌함", "기대감", "희망적",
        "평온", "덤덤함", "흥미로움", "신중함", "중립", "무감정", "보통", "무관심", "냉정", "담담함",
        "걱정", "긴장", "당황", "피곤", "지침", "미묘함", "심심함", "무료함", "멍함", "정신 없음",
        "혼란", "어색함", "부끄러움", "민망함", "궁금함", "어리둥절", "귀찮음", "피로감", "허기짐",
        "불안", "초조", "실망", "외로움", "서운함", "후회", "죄책감", "지루함", "권태", "공허함",
        "허무함", "무의미함", "의욕 없음", "의욕 상실", "무력감", "허탈함", "공백감", "답답함",
        "불만", "억울", "혼돈", "불확실", "걱정스러움", "조바심", "망설임", "씁쓸함",
        "슬픔", "우울", "짜증", "분노", "불행", "상처", "비참", "무기력", "고통", "억울함",
        "열등감", "시기심", "부러움", "답답",
        "절망", "절망감", "공포", "두려움", "혐오", "증오", "극심한 분노", "치욕", "수치심",
        "비통함", "고독"
    ]


    func analyzeDiaryText(_ text: String, completion: @escaping AnalyzeCompletion) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            self.requestWithBackoff(text: text, retryCount: 0, completion: completion)
        }
    }

    private func requestWithBackoff(text: String, retryCount: Int, completion: @escaping AnalyzeCompletion) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            completion(nil, nil, nil, NSError(domain: "Gemini API key missing in Info.plist", code: 0))
            return
        }

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)") else {
            completion(nil, nil, nil, NSError(domain: "Invalid Gemini URL", code: 0))
            return
        }

        let messages: [[String: Any]] = [
            [
                "role": "user",
                "parts": [
                    ["text": """
                    당신은 일기 텍스트를 분석하고 JSON 객체만 반환하는 도우미입니다.
                    JSON은 'summary', 'emotion', 'solution'이라는 키만 포함해야 합니다.
                    JSON 외의 다른 설명, 인사 또는 텍스트는 포함하지 마십시오.
                    응답은 한국어로 해주세요.

                    일기 텍스트:
                    \(text)
                    """]
                ]
            ]
        ]

        let body: [String: Any] = [
            "contents": messages,
            "safetySettings": [
                ["category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"]
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            completion(nil, nil, nil, NSError(domain: "Invalid request body", code: 0))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, nil, nil, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, nil, nil, NSError(domain: "Invalid HTTP response", code: 0))
                return
            }

            if httpResponse.statusCode != 200 {
                if let data = data, let errorText = String(data: data, encoding: .utf8) {
                    print("❌ Gemini 오류 응답: \(errorText)")
                }
                completion(nil, nil, nil, NSError(domain: "Gemini HTTP Error", code: httpResponse.statusCode))
                return
            }

            guard let data = data else {
                completion(nil, nil, nil, NSError(domain: "No data from Gemini", code: 0))
                return
            }

            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Gemini 응답 원본:\n\(responseString)")
            }

            do {
                guard
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let candidates = json["candidates"] as? [[String: Any]],
                    let content = candidates.first?["content"] as? [String: Any],
                    let parts = content["parts"] as? [[String: Any]],
                    let textContent = parts.first?["text"] as? String,
                    let textData = textContent.data(using: .utf8)
                else {
                    throw NSError(domain: "Invalid Gemini response structure", code: 0)
                }

                if let result = try? JSONSerialization.jsonObject(with: textData) as? [String: String] {
                    let filteredEmotion = self.filterAllowedEmotions(from: result["emotion"])
                    completion(result["summary"], filteredEmotion, result["solution"], nil)
                } else {
                    // 정규식으로 JSON 추출 시도
                    let pattern = "\\{.*\\}"
                    if let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
                       let match = regex.firstMatch(in: textContent, range: NSRange(location: 0, length: textContent.utf16.count)),
                       let range = Range(match.range, in: textContent),
                       let jsonData = String(textContent[range]).data(using: .utf8),
                       let extracted = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] {
                        let filteredEmotion = self.filterAllowedEmotions(from: extracted["emotion"])
                        completion(extracted["summary"], filteredEmotion, extracted["solution"], nil)
                    } else {
                        completion(nil, nil, nil, NSError(domain: "Gemini JSON parsing failed", code: 0))
                    }
                }

            } catch {
                completion(nil, nil, nil, error)
            }
        }

        task.resume()
    }

    // ✅ 이 함수가 필수입니다!
    private func filterAllowedEmotions(from emotionString: String?) -> String? {
        guard let emotionString = emotionString else { return nil }
        
        let components = emotionString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        let filtered = components.filter { allowedEmotions.contains($0) }
        
        return filtered.joined(separator: ", ")
    }
}
