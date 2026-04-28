import Foundation

struct ColumnSubtractionMethod: ArithmeticMethod {
    let id = "column-subtraction"
    let displayName = "Column subtraction"

    func makeLayout(for problem: ArithmeticProblem) -> SheetLayout {
        let top = problem.operands.first ?? 0
        let bottom = problem.operands.dropFirst().first ?? 0
        let maxDigits = max(String(top).count, String(bottom).count, 1)
        let answerDigits = String(max(top - bottom, 0)).count
        let columnCount = max(maxDigits, answerDigits)
        let columns = (0..<columnCount).map { index in
            let place = columnCount - index - 1
            return SheetColumn(id: index, place: place, label: PlaceValue.label(for: place))
        }

        let rows = [
            SheetRow(id: 0, label: nil, role: .carry),
            SheetRow(id: 1, label: nil, role: .operand(index: 0)),
            SheetRow(id: 2, label: "-", role: .operand(index: 1)),
            SheetRow(id: 3, label: nil, role: .answer)
        ]

        var cells: [SheetCell] = []
        for row in rows {
            for column in columns {
                let fixedText: String?
                let role: SheetCellRole
                let isEditable: Bool

                switch row.role {
                case .carry:
                    fixedText = nil
                    role = .borrowMark
                    isEditable = column.place < columnCount - 1
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
        let top = problem.operands.first ?? 0
        let bottom = problem.operands.dropFirst().first ?? 0
        let answer = max(top - bottom, 0)
        let highestAnswerPlace = max(PlaceValue.digitsByPlace(answer).keys.max() ?? 0, 0)
        var borrowFromPreviousColumn = 0
        var steps: [SheetStep] = []

        for column in layout.columns.sorted(by: { $0.place < $1.place }) {
            let topDigit = PlaceValue.digit(top, atPlace: column.place)
            let bottomDigit = PlaceValue.digit(bottom, atPlace: column.place)
            let adjustedTopDigit = topDigit - borrowFromPreviousColumn
            let needsBorrow = adjustedTopDigit < bottomDigit
            let workingTopDigit = needsBorrow ? adjustedTopDigit + 10 : adjustedTopDigit
            let answerDigit = workingTopDigit - bottomDigit

            if needsBorrow {
                let borrowCell = SheetCellID(row: 0, column: column.id)
                steps.append(
                    SheetStep(
                        title: "Borrow for \(column.label)",
                        prompt: borrowPrompt(
                            column: column,
                            adjustedTopDigit: adjustedTopDigit,
                            bottomDigit: bottomDigit,
                            workingTopDigit: workingTopDigit
                        ),
                        highlightedCells: [borrowCell],
                        expectedMarks: [
                            ExpectedMark(
                                cellID: borrowCell,
                                kind: .digit,
                                value: "1",
                                successMessage: "That borrowed ten is now available in the \(column.label) column.",
                                mistakeMessage: "Mark a 1 above the \(column.label) column to show one ten has been borrowed."
                            )
                        ]
                    )
                )
            }

            if column.place <= highestAnswerPlace {
                let answerCell = SheetCellID(row: 3, column: column.id)
                steps.append(
                    SheetStep(
                        title: "\(column.label.capitalized) answer",
                        prompt: answerPrompt(
                            column: column,
                            topDigit: topDigit,
                            bottomDigit: bottomDigit,
                            borrowFromPreviousColumn: borrowFromPreviousColumn,
                            workingTopDigit: workingTopDigit,
                            answerDigit: answerDigit
                        ),
                        highlightedCells: [answerCell],
                        expectedMarks: [
                            ExpectedMark(
                                cellID: answerCell,
                                kind: .digit,
                                value: String(answerDigit),
                                successMessage: "\(answerDigit) belongs in the \(column.label) answer place.",
                                mistakeMessage: "That digit does not match the \(column.label) subtraction."
                            )
                        ]
                    )
                )
            }

            borrowFromPreviousColumn = needsBorrow ? 1 : 0
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
            return .rejected(message: "Use the highlighted answer place for this subtraction step.")
        case .borrowMark:
            return .rejected(message: "Borrow marks go above the column that needs the extra ten.")
        default:
            return .ignored(message: state.currentStep?.prompt ?? "")
        }
    }

    private func borrowPrompt(
        column: SheetColumn,
        adjustedTopDigit: Int,
        bottomDigit: Int,
        workingTopDigit: Int
    ) -> String {
        if adjustedTopDigit < 0 {
            return "The earlier borrow has already used one from this column, so borrow again through the \(column.label) column. Mark the borrowed 1 above this column to make \(workingTopDigit)."
        }
        return "\(adjustedTopDigit) is smaller than \(bottomDigit), so borrow one ten for the \(column.label) column. Mark the borrowed 1 above this column to make \(workingTopDigit)."
    }

    private func answerPrompt(
        column: SheetColumn,
        topDigit: Int,
        bottomDigit: Int,
        borrowFromPreviousColumn: Int,
        workingTopDigit: Int,
        answerDigit: Int
    ) -> String {
        if borrowFromPreviousColumn > 0 {
            if topDigit == 0 {
                return "The previous borrow has passed through this zero, leaving \(workingTopDigit) to use in the \(column.label) column. \(workingTopDigit) - \(bottomDigit) = \(answerDigit). Write \(answerDigit)."
            }
            return "The previous borrow reduces this \(column.label) digit from \(topDigit) to \(topDigit - borrowFromPreviousColumn). \(workingTopDigit) - \(bottomDigit) = \(answerDigit). Write \(answerDigit)."
        }
        return "Subtract the \(column.label): \(workingTopDigit) - \(bottomDigit) = \(answerDigit). Write \(answerDigit)."
    }
}
