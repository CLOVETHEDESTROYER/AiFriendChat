//
//  ScenarioSelectionView.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/23/24.
//


import SwiftUI

struct ScenarioSelectionView: View {
    @Binding var selectedScenario: String
    let scenarios = ["default", "sister_emergency", "mother_emergency"]

    var body: some View {
        Picker("Select Scenario", selection: $selectedScenario) {
            ForEach(scenarios, id: \.self) { scenario in
                Text(scenario.replacingOccurrences(of: "_", with: " ").capitalized)
                    .tag(scenario)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
}
