import SwiftUI

struct ArithmeticSheetView: View {
    @ObservedObject var session: SheetSession

    private let cellSize: CGFloat = 56

    var body: some View {
        VStack(spacing: 18) {
            header

            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 10) {
                    placeLabels
                    sheetGrid
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(.systemBackground))

            feedbackPanel
            DigitPadView(
                onDigit: session.enterDigit,
                onClear: session.clearSelectedCell
            )
            .disabled(session.isComplete)
            .opacity(session.isComplete ? 0.45 : 1)
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.method.displayName)
                    .font(.headline)
                Text(problemText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                session.showCurrentStepMark()
            } label: {
                Image(systemName: "lightbulb")
                    .font(.body.weight(.semibold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(session.isComplete)
            .opacity(session.isComplete ? 0.4 : 1)
            .accessibilityLabel("Show this mark")

            Button {
                session.reset(problem: session.problem)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.body.weight(.semibold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Restart this sheet")

            Text(stepCountText)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemFill), in: Capsule())
        }
        .padding(.horizontal, 20)
    }

    private var placeLabels: some View {
        HStack(spacing: 8) {
            rowLabel(nil)
            ForEach(session.layout.columns) { column in
                Text(column.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: cellSize)
            }
        }
    }

    private var sheetGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(session.layout.rows) { row in
                HStack(spacing: 8) {
                    rowLabel(row.label)
                    ForEach(session.layout.columns) { column in
                        let cellID = SheetCellID(row: row.id, column: column.id)
                        sheetCell(cellID: cellID)
                    }
                }
                if row.id == session.layout.rows.dropLast().last?.id {
                    ruleLine
                }
            }
        }
    }

    private var ruleLine: some View {
        HStack(spacing: 8) {
            rowLabel(nil)
            Rectangle()
                .fill(Color.primary)
                .frame(width: CGFloat(session.layout.columns.count) * cellSize + CGFloat(max(session.layout.columns.count - 1, 0)) * 8, height: 2)
        }
    }

    private var feedbackPanel: some View {
        Text(session.feedback)
            .font(.body)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 20)
    }

    private var stepCountText: String {
        if session.isComplete {
            return "Done"
        }
        return "\(session.currentStepIndex + 1) of \(session.steps.count)"
    }

    private var problemText: String {
        session.problem.operands.map(String.init).joined(separator: " + ")
    }

    private func rowLabel(_ text: String?) -> some View {
        Text(text ?? "")
            .font(.title3.weight(.semibold))
            .frame(width: 28, height: cellSize)
    }

    private func sheetCell(cellID: SheetCellID) -> some View {
        let cell = session.layout.cell(id: cellID)
        let mark = session.mark(for: cellID)
        let isHighlighted = session.activeHighlightedCells.contains(cellID)
        let isSelected = session.selectedCellID == cellID
        let isEditable = cell?.isEditable == true

        return Button {
            session.select(cellID)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor(isEditable: isEditable, isHighlighted: isHighlighted))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(borderColor(isSelected: isSelected, isHighlighted: isHighlighted), lineWidth: isSelected ? 3 : 1)
                    }

                Text(mark?.value ?? cell?.fixedText ?? "")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(cell?.fixedText == nil ? Color.accentColor : Color.primary)
                    .monospacedDigit()
            }
            .frame(width: cellSize, height: cellSize)
        }
        .buttonStyle(.plain)
        .disabled(!isEditable)
        .accessibilityLabel(accessibilityLabel(for: cellID))
    }

    private func backgroundColor(isEditable: Bool, isHighlighted: Bool) -> Color {
        if isHighlighted {
            return Color.accentColor.opacity(0.18)
        }
        if isEditable {
            return Color(.systemBackground)
        }
        return Color.clear
    }

    private func borderColor(isSelected: Bool, isHighlighted: Bool) -> Color {
        if isSelected {
            return .accentColor
        }
        if isHighlighted {
            return .accentColor.opacity(0.75)
        }
        return Color(.separator)
    }

    private func accessibilityLabel(for cellID: SheetCellID) -> String {
        guard let cell = session.layout.cell(id: cellID) else {
            return "Sheet cell"
        }

        switch cell.role {
        case .operandDigit:
            return "Operand digit"
        case .operatorSymbol:
            return "Operator"
        case .answerDigit:
            return "Answer digit"
        case .carryDigit:
            return "Carry digit"
        case .borrowMark:
            return "Borrow mark"
        case .regroupedDigit:
            return "Regrouped digit"
        case .partialProductDigit:
            return "Partial product digit"
        case .quotientDigit:
            return "Quotient digit"
        case .remainderDigit:
            return "Remainder digit"
        case .workingDigit:
            return "Working digit"
        case .ruleLine:
            return "Rule line"
        }
    }
}
