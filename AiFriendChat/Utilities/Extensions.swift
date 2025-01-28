//
//  Extensions.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 1/21/25.
//

import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
