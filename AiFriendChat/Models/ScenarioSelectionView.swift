import SwiftUI

struct ScenarioSelectionView: View {
    @Binding var selectedScenario: String
    let scenarios = ["default", "sister_emergency", "mother_emergency"]

    var body: some View {
        Picker("Select Scenario", selection: $selectedScenario) {
            ForEach(scenarios, id: \.self) { scenario in
                Text(scenario.capitalized).tag(scenario)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
}