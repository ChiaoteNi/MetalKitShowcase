//
//  ViewModifiers.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/28.
//

import SwiftUI

struct RoundedOptionCellModifier: ViewModifier {
    let isHighlighted: Bool

    init(isHighlighted: Bool) {
        self.isHighlighted = isHighlighted
    }

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5).stroke(
                    isHighlighted ? Color.cyan : Color.gray,
                    lineWidth: isHighlighted ? 3 : 1
                )
            )
            .shadow(radius: 5)
    }
}

struct LeadingAlignedHeaderModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .bold()
            .font(.title3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.leading, .trailing], 5)
    }
}
