import SwiftUI

struct HelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text("""
                AiDiary는 여러분의 하루를 기록하는 일기 앱입니다.
                단순히 일기를 작성하고 저장하는 것을 넘어, AI 분석을 통해
                여러분이 느낀 감정을 깨닫고, 나아가 해결책까지 제안받을 수 있습니다.
                또한 설정에서 자신의 감정을 1주일치 한달치로 비교할 수 있습니다.

                - 하루에 한 편, 당일 날짜에만 일기 작성이 가능합니다.

                - 작성한 일기의 AI 분석 결과는 달력에서 해당 날짜를 
                  클릭해 확인할 수 있습니다.

                - 작성한 일기는 삭제할 수 있습니다.

                - 설정 화면에서 애플 계정 연동을 지원합니다.
                """)
                .padding()
            }
            .navigationTitle("앱 설명서")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
