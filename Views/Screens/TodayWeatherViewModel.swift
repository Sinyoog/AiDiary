import Foundation
import Combine

class TodayWeatherViewModel: ObservableObject { // 클래스 이름 변경
    @Published var temperature: String = "-"
    @Published var sky: String = "로딩 중..."
    @Published var isLoading = true
    @Published var errorMessage: String?

    func loadWeather() {
        isLoading = true
        errorMessage = nil

        // ⭐⭐ fetchTodayWeather 호출로 변경 ⭐⭐
        WeatherService.fetchTodayWeather { [weak self] result in // 함수 호출 변경
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.isLoading = false
                switch result {
                case .success(let weather):
                    self.temperature = weather.temperature
                    self.sky = weather.sky
                    print("✅ 온도: \(weather.temperature), 상태: \(weather.sky)")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.temperature = "-"
                    self.sky = "정보 없음"
                    print("❌ 오류: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("➡️ 에러 도메인: \(nsError.domain), 코드: \(nsError.code)")
                        if let userInfo = nsError.userInfo as? [String: Any] {
                            print("➡️ UserInfo:", userInfo)
                        }
                    }
                }
            }
        }
    }
}
