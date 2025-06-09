import SwiftUI

struct TodayWeatherView: View { // 구조체 이름 변경
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TodayWeatherViewModel() // 뷰 모델 변경

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("불러오는 중...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text("에러 발생: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        Text("☀️ 오늘의 날씨") // 텍스트 변경
                            .font(.title)
                            .bold()

                        Text("기온: \(viewModel.temperature)°C")
                            .font(.title2)

                        Text("하늘 상태: \(viewModel.sky)")
                            .font(.title3)
                    }
                    .padding()
                }

                Button("다시 불러오기") {
                    viewModel.loadWeather()
                }
                .padding(.top, 20)

                Spacer()
            }
            .navigationTitle("날씨 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadWeather()
            }
        }
    }
}
