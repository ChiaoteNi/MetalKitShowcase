//
//  ViewModifiers.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/28.
//

import SwiftUI

struct RoundedOptionCellModifier: ViewModifier {
    let isHighlighted: Bool
    let cornerRadius: CGFloat

    init(isHighlighted: Bool, cornerRadius: CGFloat = 5) {
        self.isHighlighted = isHighlighted
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .clipShape(shape(cornerRadius: cornerRadius))
            .background(
                shape(cornerRadius: cornerRadius)
                    .stroke(
                        isHighlighted ? Color.cyan : Color.gray,
                        lineWidth: isHighlighted ? 3 : 1
                    )
            )
            .shadow(color: Color/*@START_MENU_TOKEN@*/.black/*@END_MENU_TOKEN@*/.opacity(0.1), radius: 5)
    }

    @ViewBuilder
    private func shape(cornerRadius: CGFloat) -> some Shape {
        RoundedRectangle(cornerRadius: cornerRadius)
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
