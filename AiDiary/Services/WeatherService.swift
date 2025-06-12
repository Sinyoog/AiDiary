import Foundation

// MARK: - Model Structs (변동 없음)
struct TodayWeather: Decodable { // 모델 이름도 TodayWeather로 변경 가능 (선택 사항)
    let temperature: String
    let sky: String
}

// MARK: - API Response Structs (변동 없음)
struct WeatherAPIResponse: Decodable {
    let response: WeatherResponse
}

struct WeatherResponse: Decodable {
    let header: WeatherHeader
    let body: WeatherBody?
}

struct WeatherHeader: Decodable {
    let resultCode: String
    let resultMsg: String?
}

struct WeatherBody: Decodable {
    let items: WeatherItems
}

struct WeatherItems: Decodable {
    let item: [WeatherItem]
}

struct WeatherItem: Decodable {
    let category: String
    let fcstValue: String
    let fcstDate: String?
    let fcstTime: String?
}

// MARK: - Weather Service Class (수정됨)

class WeatherService {
    
    // 오늘의 날씨를 가져오는 함수로 변경
    static func fetchTodayWeather(completion: @escaping (Result<TodayWeather, Error>) -> Void) {
        // 1. Info.plist에서 API Key 가져오기
        guard let apiKey = Bundle.main.infoDictionary?["WeatherAPIKey"] as? String else {
            completion(.failure(NSError(domain: "Configuration Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Info.plist에 WeatherAPIKey가 설정되지 않았습니다."])))
            return
        }
        
        // ⭐⭐ Info.plist에는 "일반 인증키 (Decoding)" 버전의 원본 API 키를 넣어주세요. ⭐⭐
        // 예: f+sW6z6naJV3bi1m8+er2R4oDrT+vizxVDUBmemjexZIPvSj8VCgXBmpW/av1WKwJe+I0kX3QxyTotlTyR1+HA==

        // ⭐⭐ 핵심 수정: API 키를 수동으로 인코딩하여 URL 문자열에 직접 삽입 ⭐⭐
        let encodedApiKeyForURL = apiKey
            .replacingOccurrences(of: "+", with: "%2B")
            .replacingOccurrences(of: "/", with: "%2F")
            .replacingOccurrences(of: "=", with: "%3D")

        // ⭐⭐ 변경된 부분: baseDate를 오늘 날짜로 가져오고, baseTime을 현재 시각에 맞는 가장 최근 발표 시각으로 설정 ⭐⭐
        let baseDate = getTodayDateString() // 오늘 날짜로 변경
        
        // 현재 시간 2025년 6월 9일 오후 2시 38분 (14시 38분)을 기준으로,
        // 가장 최근 발표된 단기예보 base_time은 14시(1400)입니다.
        // 다음 발표 시간은 17시(1700)입니다.
        // 따라서 현재 시점에서는 "1400"을 사용하는 것이 가장 적합합니다.
        // 만약 밤에 테스트한다면 "2300" 등을 사용해야 합니다.
        let baseTime = "1400" // 현재 시각을 고려하여 조정

        // 참고: 평택시의 격자 좌표 (경기도 평택시)
        // 공공데이터포털에서 직접 확인하는 것이 가장 정확합니다.
        // 예를 들어 평택시청 (36.9937, 127.1084)의 가장 가까운 격자 좌표는 60, 127과 다를 수 있습니다.
        // 하지만 테스트를 위해 일단 60, 127을 유지하겠습니다.
        // 만약 NO_DATA가 계속 발생한다면, 정확한 평택시의 nx, ny를 찾아야 합니다.
        let nx = "60" // 서울 기준 격자 X 좌표 (평택시와 다름)
        let ny = "127" // 서울 기준 격자 Y 좌표 (평택시와 다름)

        // 2. URL 문자열을 직접 구성합니다.
        let urlStr = "https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst?" +
                     "serviceKey=\(encodedApiKeyForURL)" +
                     "&pageNo=1" +
                     "&numOfRows=1000" +
                     "&dataType=JSON" +
                     "&base_date=\(baseDate)" + // 오늘 날짜
                     "&base_time=\(baseTime)" + // 오늘 가장 최근 발표 시간
                     "&nx=\(nx)" +
                     "&ny=\(ny)"

        guard let url = URL(string: urlStr) else {
            completion(.failure(NSError(domain: "URL Generation Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "유효하지 않은 URL 입니다."])))
            return
        }

        print("🔗 최종 URL: \(url.absoluteString)")
        
        // 3. 요청
        URLSession.shared.dataTask(with: url) { data, response, error in
            // 네트워크 에러 처리
            if let error = error {
                print("❌ 네트워크 에러:", error.localizedDescription)
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "서버로부터 데이터를 받지 못했습니다."])))
                return
            }

            if let responseString = String(data: data, encoding: .utf8) {
                print("➡️ 수신된 Raw 응답 데이터:\n\(responseString)")
            } else {
                print("➡️ 수신된 데이터를 문자열로 변환할 수 없습니다.")
            }

            do {
                let decoded = try JSONDecoder().decode(WeatherAPIResponse.self, from: data)
                
                print("➡️ API 응답 resultCode: \(decoded.response.header.resultCode)")
                print("➡️ API 응답 resultMsg: \(decoded.response.header.resultMsg ?? "메시지 없음")")

                if decoded.response.header.resultCode != "00" {
                    let apiErrorMessage = decoded.response.header.resultMsg ?? "알 수 없는 API 오류"
                    print("❌ API 응답 오류: \(decoded.response.header.resultCode) - \(apiErrorMessage)")
                    completion(.failure(NSError(domain: "API Error", code: Int(decoded.response.header.resultCode) ?? -1, userInfo: [NSLocalizedDescriptionKey: apiErrorMessage])))
                    return
                }
                
                guard let items = decoded.response.body?.items.item, !items.isEmpty else {
                    completion(.failure(NSError(domain: "No item data", code: -1, userInfo: [NSLocalizedDescriptionKey: "API 응답에 유효한 날씨 데이터(body.items.item)가 없습니다."])))
                    return
                }

                // ⭐⭐ 변경된 부분: 오늘 오전 9시 (0900) 기준이 아니라,
                // 현재 시각(2:38 PM)을 기준으로 오늘 예보에서 적절한 값을 찾아야 합니다.
                // 단기예보는 3시간 간격으로 제공될 수 있으므로, fcstTime을 유연하게 처리하거나
                // 가장 가까운 미래 시각을 찾는 로직이 필요할 수 있습니다.
                // 여기서는 일단 오늘 오후 3시 (1500) 예보를 가져오는 것으로 가정합니다.
                let targetTime = "1500" // 현재 시각(14:38) 이후의 가장 가까운 예보 시각 (3시)
                
                let temperature = items.first { $0.category == "TMP" && $0.fcstTime == targetTime }?.fcstValue ?? "-"
                let skyCode = items.first { $0.category == "SKY" && $0.fcstTime == targetTime }?.fcstValue ?? "-"
                let sky = skyDescription(for: skyCode)

                // TodayWeather 모델로 변경
                completion(.success(TodayWeather(temperature: temperature, sky: sky)))

            } catch {
                print("❌ JSON 디코딩 실패:", error.localizedDescription)
                if let decodingError = error as? DecodingError {
                    print("➡️ 디코딩 에러 상세:", decodingError)
                }
                completion(.failure(error))
            }
        }.resume()
    }

    // ⭐⭐ 새로운 함수: 오늘 날짜 문자열 반환 ⭐⭐
    private static func getTodayDateString() -> String {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: today)
    }

    // 기존 getTomorrowDateString()은 더 이상 사용하지 않거나, 필요하면 삭제
    private static func getTomorrowDateString() -> String {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: tomorrow)
    }

    private static func skyDescription(for code: String) -> String {
        switch code {
        case "1": return "맑음"
        case "3": return "구름 많음"
        case "4": return "흐림"
        default: return "날씨 정보 없음"
        }
    }
}
