import SwiftUI

struct DigitPadView: View {
    var onDigit: (Int) -> Void
    var onClear: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0...9, id: \.self) { digit in
                Button {
                    onDigit(digit)
                } label: {
                    Text(String(digit))
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            Button {
                onClear()
            } label: {
                Image(systemName: "delete.left")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear selected cell")
        }
        .padding(.horizontal, 20)
    }
}
