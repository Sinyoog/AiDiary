import SwiftUI
import UIKit

struct UIKitTextView: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.delegate = context.coordinator
        textView.backgroundColor = UIColor.systemGray6
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: UIKitTextView

        init(_ parent: UIKitTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
