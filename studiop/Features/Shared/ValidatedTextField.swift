import SwiftUI

struct ValidatedTextField: View {
    let title: String
    @Binding var field: ValidatedField<String>
    var isSecure: Bool = false
    let validate: (String) -> String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                if isSecure {
                    SecureField(title, text: $field.value)
                } else {
                    TextField(title, text: $field.value)
                }
            }
            .textFieldStyle(.roundedBorder)
            .onChange(of: field.value) {
                field.error = validate(field.value)
            }

            if let error = field.error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }
}

private struct ValidatedTextFieldPreviewContainer: View {
    @State private var field = ValidatedField<String>(value: "")

    var body: some View {
        ValidatedTextField(title: "Email", field: $field) { value in
            value.isEmpty ? "Required" : nil
        }
        .padding()
    }
}

#Preview {
    ValidatedTextFieldPreviewContainer()
}
