import SwiftUI
import AuthenticationServices
import CoreData

struct SettingsView: View {
    @Binding var showSettings: Bool
    @State private var showHelp = false
    @State private var showEmotionComparison = false
    @State private var showWeather = false
    
    @Environment(\.managedObjectContext) private var context
    
    @State private var isSignedInWithApple = false
    
    func customButton(title: String, background: Color = Color.blue, foreground: Color = Color.white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 200, height: 45)
                .background(background)
                .foregroundColor(foreground)
                .cornerRadius(8)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Spacer().frame(height: 40) // 닫기 버튼과 타이틀 사이 여백
                
                // 설정 버튼들
                customButton(title: "앱 설명서 보기", background: Color.gray.opacity(0.2), foreground: Color.blue) {
                    showHelp = true
                }
                .sheet(isPresented: $showHelp) {
                    HelpView()
                }
                
                customButton(title: "감정 비교", background: Color.blue, foreground: Color.white) {
                    showEmotionComparison = true
                }
                .sheet(isPresented: $showEmotionComparison) {
                    EmotionComparisonView()
                        .environment(\.managedObjectContext, context)
                }
                
                
                customButton(title: "내일 날씨 보기", background: Color.cyan) {
                    showWeather = true
                }
                .sheet(isPresented: $showWeather) {
                    TodayWeatherView()
                }
                
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            print("성공: \(authResults)")
                            isSignedInWithApple = true
                        case .failure(let error):
                            print("실패: \(error.localizedDescription)")
                            isSignedInWithApple = false
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(width: 200, height: 45)
                .cornerRadius(8)
                .scaleEffect(0.95)
                
                customButton(title: "게임 종료", background: Color.red) {
                    exit(0)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .navigationTitle("AiDiary 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        showSettings = false
                    }
                }
            }
        }
    }
}
