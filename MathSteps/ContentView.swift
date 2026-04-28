import SwiftUI

struct ContentView: View {
    @StateObject private var session = SheetSession(
        problem: ArithmeticProblem(operands: [347, 286], operation: .addition),
        method: ColumnAdditionMethod()
    )
    @State private var topNumber = "347"
    @State private var bottomNumber = "286"
    @State private var operation: ArithmeticOperation = .addition
    @State private var inputMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    appHeader
                    problemEntry
                    ArithmeticSheetView(session: session)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Math Steps")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var appHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Math Steps")
                    .font(.title2.weight(.bold))
                Text("Smart paper for written arithmetic")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color(.systemBackground))
    }

    private var problemEntry: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                NumberField(title: "Top", text: $topNumber)
                Picker("Operation", selection: $operation) {
                    Text(ArithmeticOperation.addition.symbol).tag(ArithmeticOperation.addition)
                    Text(ArithmeticOperation.subtraction.symbol).tag(ArithmeticOperation.subtraction)
                }
                .pickerStyle(.segmented)
                .frame(width: 84)
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
            inputMessage = "Use whole numbers for this first method."
            return
        }

        if operation == .subtraction, bottom > top {
            inputMessage = "This first subtraction method keeps the answer positive. Put the larger number on top."
            return
        }

        let problem = ArithmeticProblem(operands: [top, bottom], operation: operation)
        session.reset(problem: problem, method: method(for: operation))
        inputMessage = nil
    }

    private func method(for operation: ArithmeticOperation) -> any ArithmeticMethod {
        switch operation {
        case .addition:
            return ColumnAdditionMethod()
        case .subtraction:
            return ColumnSubtractionMethod()
        case .multiplication, .division:
            return ColumnAdditionMethod()
        }
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
