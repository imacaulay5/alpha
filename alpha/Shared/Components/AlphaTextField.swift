//
//  AlphaTextField.swift
//  alpha
//
//  Custom text field with blue cursor and grey placeholder
//

import SwiftUI
import UIKit

struct AlphaTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var textContentType: UITextContentType?
    var isSecure: Bool = false
    var disableAutocorrection: Bool = false

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        textField.autocapitalizationType = autocapitalization
        textField.autocorrectionType = disableAutocorrection ? .no : .default
        textField.textContentType = textContentType
        textField.isSecureTextEntry = isSecure

        // Set cursor color to blue
        textField.tintColor = UIColor(Color.alphaInfo)

        // Set text color to primary (adaptive)
        textField.textColor = UIColor.label

        // Set placeholder with grey color
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.placeholderText
            ]
        )

        // Set font
        textField.font = UIFont.systemFont(ofSize: 16)

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if let text = textField.text,
               let textRange = Range(range, in: text) {
                let updatedText = text.replacingCharacters(in: textRange, with: string)
                self.text = updatedText
            }
            return true
        }
    }
}
