import SwiftUI

struct ContentView: View {
    @StateObject private var session = SheetSession(
        problem: ArithmeticProblem(operands: [347, 286], operation: .addition),
        method: ColumnAdditionMethod()
    )
    @State private var topNumber = "347"
    @State private var bottomNumber = "286"
    @State private var inputMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                problemEntry
                ArithmeticSheetView(session: session)
            }
                .navigationTitle("Math Steps")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var problemEntry: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                NumberField(title: "Top", text: $topNumber)
                Text("+")
                    .font(.title2.weight(.semibold))
                    .frame(width: 24)
                NumberField(title: "Bottom", text: $bottomNumber)
                Button("Set") {
                    setProblem()
                }
                .buttonStyle(.borderedProminent)
            }

            Picker("Support", selection: $session.supportLevel) {
                ForEach(SupportLevel.allCases) { level in
                    Text(level.label).tag(level)
                }
            }
            .pickerStyle(.segmented)

            if let inputMessage {
                Text(inputMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
    }

    private func setProblem() {
        guard let top = Int(topNumber), let bottom = Int(bottomNumber), top >= 0, bottom >= 0 else {
            inputMessage = "Use whole numbers for this first addition method."
            return
        }

        let problem = ArithmeticProblem(operands: [top, bottom], operation: .addition)
        session.reset(problem: problem)
        inputMessage = nil
    }
}

private extension SupportLevel {
    var label: String {
        switch self {
        case .independent:
            return "Free"
        case .guided:
            return "Guided"
        case .worked:
            return "Worked"
        }
    }
}

private struct NumberField: View {
    var title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(title, text: $text)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .monospacedDigit()
        }
    }
}
