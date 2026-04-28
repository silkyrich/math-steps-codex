import Foundation

struct ColumnAdditionMethod: ArithmeticMethod {
    let id = "column-addition"
    let displayName = "Column addition"

    func makeLayout(for problem: ArithmeticProblem) -> SheetLayout {
        let maxDigits = max(problem.operands.map { String($0).count }.max() ?? 1, 1)
        let answerDigits = String(problem.operands.reduce(0, +)).count
        let columnCount = max(maxDigits, answerDigits)
        let columns = (0..<columnCount).map { index in
            let place = columnCount - index - 1
            return SheetColumn(id: index, place: place, label: PlaceValue.label(for: place))
        }

        var rows = [SheetRow(id: 0, label: nil, role: .carry)]
        rows += problem.operands.enumerated().map { index, _ in
            SheetRow(id: index + 1, label: index == problem.operands.count - 1 ? "+" : nil, role: .operand(index: index))
        }
        rows.append(SheetRow(id: problem.operands.count + 1, label: nil, role: .answer))

        var cells: [SheetCell] = []
        for row in rows {
            for column in columns {
                let fixedText: String?
                let role: SheetCellRole
                let isEditable: Bool

                switch row.role {
                case .carry:
                    fixedText = nil
                    role = .carryDigit
                    isEditable = column.place > 0
                case .operand(let operandIndex):
                    fixedText = PlaceValue.digitText(problem.operands[operandIndex], atPlace: column.place)
                    role = .operandDigit(operandIndex: operandIndex)
                    isEditable = false
                case .answer:
                    fixedText = nil
                    role = .answerDigit
                    isEditable = true
                case .working, .quotient, .divider:
                    fixedText = nil
                    role = .workingDigit
                    isEditable = true
                }

                cells.append(
                    SheetCell(
                        id: SheetCellID(row: row.id, column: column.id),
                        role: role,
                        fixedText: fixedText,
                        isEditable: isEditable
                    )
                )
            }
        }

        return SheetLayout(rows: rows, columns: columns, cells: cells)
    }

    func makeSteps(for problem: ArithmeticProblem, layout: SheetLayout) -> [SheetStep] {
        let sum = problem.operands.reduce(0, +)
        let answer = PlaceValue.digitsByPlace(sum)
        var carry = 0
        var steps: [SheetStep] = []

        for column in layout.columns.sorted(by: { $0.place < $1.place }) {
            let columnTotal = problem.operands.reduce(carry) { total, operand in
                total + PlaceValue.digit(operand, atPlace: column.place)
            }
            let answerDigit = columnTotal % 10
            let nextCarry = columnTotal / 10
            let answerCell = SheetCellID(row: problem.operands.count + 1, column: column.id)

            steps.append(
                SheetStep(
                    title: "\(column.label.capitalized) answer",
                    prompt: prompt(for: problem, column: column, carry: carry, columnTotal: columnTotal),
                    highlightedCells: [answerCell],
                    expectedMarks: [
                        ExpectedMark(
                            cellID: answerCell,
                            kind: .digit,
                            value: String(answerDigit),
                            successMessage: "\(answerDigit) belongs in the \(column.label) answer place.",
                            mistakeMessage: "That digit does not match the \(column.label) part of the column total."
                        )
                    ]
                )
            )

            if nextCarry > 0, let carryColumn = layout.columns.first(where: { $0.place == column.place + 1 }) {
                let carryCell = SheetCellID(row: 0, column: carryColumn.id)
                steps.append(
                    SheetStep(
                        title: "Carry \(nextCarry)",
                        prompt: "Carry \(nextCarry) into the \(carryColumn.label) column.",
                        highlightedCells: [carryCell],
                        expectedMarks: [
                            ExpectedMark(
                                cellID: carryCell,
                                kind: .digit,
                                value: String(nextCarry),
                                successMessage: "\(nextCarry) is now waiting in the \(carryColumn.label) column.",
                                mistakeMessage: "The carry needs to go in the next place-value column."
                            )
                        ]
                    )
                )
            }

            carry = nextCarry
        }

        let leadingPlace = (layout.columns.map(\.place).max() ?? 0)
        if let leadingDigit = answer[leadingPlace], leadingDigit > 0 {
            let leadingCell = SheetCellID(row: problem.operands.count + 1, column: 0)
            let alreadyExpected = steps.contains { step in
                step.expectedMarks.contains { $0.cellID == leadingCell }
            }
            if !alreadyExpected {
                steps.append(
                    SheetStep(
                        title: "Final carried digit",
                        prompt: "Write the final carried digit in the leftmost answer place.",
                        highlightedCells: [leadingCell],
                        expectedMarks: [
                            ExpectedMark(
                                cellID: leadingCell,
                                kind: .digit,
                                value: String(leadingDigit),
                                successMessage: "The final carried digit completes the answer.",
                                mistakeMessage: "Use the carried digit from the last column."
                            )
                        ]
                    )
                )
            }
        }

        return steps
    }

    func validate(mark: SheetMark, in state: SheetState) -> ValidationResult {
        if let result = validateExpectedMark(mark, in: state) {
            return result
        }

        guard let cell = state.layout.cell(id: mark.cellID) else {
            return .ignored(message: state.currentStep?.prompt ?? "")
        }

        switch cell.role {
        case .answerDigit:
            return .rejected(message: "Use the highlighted answer place for this step.")
        case .carryDigit:
            return .rejected(message: "Carry digits go above the next column when the column total is 10 or more.")
        default:
            return .ignored(message: state.currentStep?.prompt ?? "")
        }
    }

    private func prompt(for problem: ArithmeticProblem, column: SheetColumn, carry: Int, columnTotal: Int) -> String {
        let parts = problem.operands.map { PlaceValue.digit($0, atPlace: column.place) }
        let expression = (carry > 0 ? [carry] : []) + parts
        return "Add the \(column.label): \(expression.map(String.init).joined(separator: " + ")) = \(columnTotal). Write the ones digit of that total here."
    }
}
