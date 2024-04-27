//
//  ImageBlendingDemoView.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/14.
//

import SwiftUI

struct ImageBlendingDemoView: View {

    @State
    private var image: UIImage?
    @State
    private var opacity: Float = 0.5
    @State
    private var blendMode: ImageBlender.BlendMode = .simpleBlend
    @State
    private var currentSourceImage: UIImage?
    @State
    private var currentBlendImage: UIImage?

    private let sourceImages: [UIImage]
    private let blendImages: [UIImage]

    private let imageBlender = ImageBlender()

    init() {
        let sourceImages = DemoImageProvider.fetchSourceImages()
        self.sourceImages = sourceImages
        self.currentSourceImage = sourceImages.first

        let blendImages = DemoImageProvider.fetchBlendImages()
        self.blendImages = blendImages
        self.currentBlendImage = blendImages.first
        self.image = blendImages.first
    }

    var body: some View {
        VStack {
            ScrollView {
                makePreViewImageView()
                makeBlendImagePicker()
                    .padding([.leading, .trailing], 10)
                    .layoutPriority(2)
                makeSourceImagePicker()
                    .padding([.leading, .trailing], 10)
                    .frame(minHeight: 100)
                    .layoutPriority(1)
                makeBlendModePicker()
                    .padding(.leading, 10)
                    .frame(minHeight: 70)
                    .layoutPriority(1)
                makeOpacitySlider()
                    .padding([.leading, .trailing], 10)
                    .layoutPriority(0)
            }
        }
        .onAppear {
            blendImage()
        }
        .onChange(of: currentSourceImage) {
            blendImage()
        }
        .onChange(of: currentBlendImage) {
            blendImage()
        }
        .onChange(of: opacity) {
            blendImage()
        }
        .onChange(of: blendMode) {
            blendImage()
        }
    }
}

// MARK: - Private functions
extension ImageBlendingDemoView {

    private func blendImage() {
        guard
            let sourceImage = currentSourceImage,
            let blendImage = currentBlendImage
        else {
            return
        }
        image = imageBlender.createBlendedImage(
            sourceImage: sourceImage,
            blendImage: blendImage,
            blendMode: blendMode,
            opacity: opacity
        )
    }

    @ViewBuilder
    private func makePreViewImageView() -> some View {
        if let image = image ?? currentSourceImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1))
                .shadow(radius: 20)
                .padding([.leading, .trailing], 10)
                .background(Color.white)

        } else {
            Spacer()
        }
    }

    @ViewBuilder
    private func makeBlendImagePicker() -> some View {
        VStack {
            Text(verbatim: "Blend Images:")
                .modifier(LeadingAlignedHeaderModifier())
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))]) {
                ForEach(blendImages, id: \.self) { blendImage in
                    Image(uiImage: blendImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 40)
                        .modifier(
                            RoundedOptionCellModifier(
                                isHighlighted: blendImage === currentBlendImage
                            )
                        )
                        .onTapGesture {
                            currentBlendImage = blendImage
                        }
                }
            }
        }
    }

    @ViewBuilder
    private func makeSourceImagePicker() -> some View {
        VStack {
            Text(verbatim: "Source Images:")
                .modifier(LeadingAlignedHeaderModifier())

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))]) {
                    ForEach(sourceImages, id: \.self) { sourceImage in
                        Image(uiImage: sourceImage)
                            .resizable()
                            .frame(width: 60, height: 48)
                            .scaledToFill()
                            .modifier(
                                RoundedOptionCellModifier(
                                    isHighlighted: sourceImage === currentSourceImage
                                )
                            )
                            .onTapGesture {
                                currentSourceImage = sourceImage
                            }
                    }
                }
        }
    }

    @ViewBuilder
    private func makeBlendModePicker() -> some View {
        VStack {
            Text(verbatim: "Blend Modes:")
                .modifier(LeadingAlignedHeaderModifier())
            LazyHStack {
                ForEach(ImageBlender.BlendMode.allCases, id: \.self) { mode in
                    Button(mode.name) {
                        blendMode = mode
                    }
                    .frame(width: 120, height: 30)
                    .modifier(
                        RoundedOptionCellModifier(
                            isHighlighted: mode == blendMode
                        )
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func makeOpacitySlider() -> some View {
        VStack {
            Text(verbatim: "Intensity:")
                .modifier(LeadingAlignedHeaderModifier())
            Slider(value: $opacity, in: 0...1, step: 0.001)
        }
    }
}

extension ImageBlender.BlendMode: CaseIterable {

    static var allCases: [ImageBlender.BlendMode] = [
        .simpleBlend,
        .screenBlend
    ]

    var name: String {
        switch self {
        case .simpleBlend:
            return "Alpha"
        case .screenBlend:
            return "Screen blend"
        }
    }
}

#Preview {
    ImageBlendingDemoView()
}
