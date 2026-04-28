import Foundation

protocol ArithmeticMethod {
    var id: String { get }
    var displayName: String { get }

    func makeLayout(for problem: ArithmeticProblem) -> SheetLayout
    func makeSteps(for problem: ArithmeticProblem, layout: SheetLayout) -> [SheetStep]
    func validate(mark: SheetMark, in state: SheetState) -> ValidationResult
}

extension ArithmeticMethod {
    func validateExpectedMark(_ mark: SheetMark, in state: SheetState) -> ValidationResult? {
        guard let currentStep = state.currentStep else {
            return .ignored(message: "The written work is complete.")
        }

        if let expected = currentStep.expectedMarks.first(where: { $0.cellID == mark.cellID }) {
            if expected.kind == mark.kind && expected.value == mark.value {
                return .accepted(message: expected.successMessage)
            }
            return .rejected(message: expected.mistakeMessage)
        }

        if currentStep.highlightedCells.contains(mark.cellID) {
            return .rejected(message: "This is the right place, but not the right mark.")
        }

        return nil
    }
}

struct SheetState {
    var problem: ArithmeticProblem
    var layout: SheetLayout
    var steps: [SheetStep]
    var currentStepIndex: Int
    var marks: [SheetMark]

    var currentStep: SheetStep? {
        guard steps.indices.contains(currentStepIndex) else {
            return nil
        }
        return steps[currentStepIndex]
    }

    func mark(for cellID: SheetCellID) -> SheetMark? {
        marks.last { $0.cellID == cellID }
    }
}
