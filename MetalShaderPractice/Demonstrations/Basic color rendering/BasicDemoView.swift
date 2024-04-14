//
//  BasicDemoView.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/14.
//

import SwiftUI
import MetalKit

struct BasicDemoView: View {

    enum ShapeOption: String, CaseIterable {
        case triangle
        case square               = "square \n(6 points)"
        case squareWith4Endpoints = "square \n(4 points)"

        var name: String {
            rawValue.prefix(1).capitalized + rawValue.dropFirst()
        }
    }

    enum ColorOption: CaseIterable {
        case green
        case orange
        case purple
        case pink
        case black
        case random

        var color: UIColor? {
            switch self {
            case .green:    return .systemCyan
            case .orange:   return .orange
            case .purple:   return .purple
            case .pink:     return .systemPink
            case .black:    return .black
            case .random:   return nil // Pass nil to allow the ColorShapeMaker to set up different colors for each endpoint.
            }
        }
    }

    enum DrawingType: String, CaseIterable {
        case point
        case line
        case lineStrip      = "line strip"
        case triangle
        case triangleStrip  = "triangle strip"

        var name: String {
            rawValue.prefix(1).capitalized + rawValue.dropFirst()
        }
    }

    @State
    private var image: UIImage?
    @State
    private var currentShape: ShapeOption = .triangle
    @State
    private var currentColor: ColorOption = .orange
    @State
    private var drawingType: DrawingType = .line
    @State
    private var shapeImageMaker = ColorShapeMaker()

    var body: some View {
        VStack {
            makePreview()
                .frame(width: 300, height: 300)
                .onChange(of: currentColor) { oldValue, newValue in
                    image = makeImage(
                        with: currentShape,
                        colorOption: newValue,
                        drawingType: drawingType
                    )
                }
                .onChange(of: currentShape) { oldValue, newValue in
                    image = makeImage(
                        with: newValue,
                        colorOption: currentColor,
                        drawingType: drawingType
                    )
                }
                .onChange(of: drawingType) { oldValue, newValue in
                    image = makeImage(
                        with: currentShape,
                        colorOption: currentColor,
                        drawingType: newValue
                    )
                }

            makeColorPicker()
            Spacer().frame(height: 20)

            makeHeader("Shape:")
            makeSwitchShapePicker()
            Spacer().frame(height: 20)

            makeHeader("Draw Type:")
            makeDrawTypePicker()
        }
        .padding()
    }
}

// MARK: - Private functions
extension BasicDemoView {

    private func makeImage(
        with shapeOption: ShapeOption,
        colorOption: ColorOption,
        drawingType: DrawingType
    ) -> UIImage? {
        let targetShape = { () -> ColorShapeMaker.Shapes in
            switch shapeOption {
            case .triangle:             return .triangle
            case .square:               return .square
            case .squareWith4Endpoints: return .squareForTriangleStrip
            }
        }()
        let drawingType = { () -> MTLPrimitiveType in
            switch drawingType {
            case .point:         return .point
            case .line:          return .line
            case .lineStrip:     return .lineStrip
            case .triangle:      return .triangle
            case .triangleStrip: return .triangleStrip
            }
        }()
        return shapeImageMaker.makeShapeImage(
            shape: targetShape,
            color: colorOption.color, 
            drawType: drawingType
        )
    }

    // MARK: - ViewBuilders

    @ViewBuilder
    private func makePreview() -> some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func makeColorPicker() -> some View {
        HStack {
            ForEach(ColorOption.allCases, id: \.self) { colorOption in
                Button(action: {
                    currentColor = colorOption
                }, label: {
                    makeColorOptionView(for: colorOption)
                        .frame(width: 30, height: 30)
                })
            }
        }
    }

    @ViewBuilder
    private func makeSwitchShapePicker() -> some View {
        HStack {
            ForEach(ShapeOption.allCases, id: \.self) { shape in
                Button(shape.name) {
                    currentShape = shape
                }
                .padding(5)
                .modifier(RoundedOptionCellModifier(isHighlighted: shape == currentShape))
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func makeDrawTypePicker() -> some View {
        HStack {
            ForEach(DrawingType.allCases, id: \.self) { drawingType in
                Button(drawingType.name) {
                    self.drawingType = drawingType
                }
                .padding(5)
                .modifier(RoundedOptionCellModifier(isHighlighted: drawingType == self.drawingType))
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func makeColorOptionView(for option: ColorOption) -> some View {
        if let color = option.color {
            Circle().fill(Color(uiColor: color))
        } else {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.red, .green, .blue]),
                        startPoint: .top,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    @ViewBuilder
    private func makeHeader(_ title: String) -> some View {
        Text(verbatim: title)
            .modifier(LeadingAlignedHeaderModifier())
    }
}

#Preview {
    BasicDemoView()
}
