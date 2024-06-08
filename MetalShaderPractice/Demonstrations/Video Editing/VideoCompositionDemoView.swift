//
//  VideoCompositionDemoView.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/20.
//

import SwiftUI
import Observation
import AVFoundation
import AVKit

struct VideoCompositionDemoView: View {

    @ObservedObject
    private var stateStore: VideoCompositionDemoViewStatesStore

    @State
    private var interactor: VideoCompositionDemoViewInteractor

    init() {
        let stateStore = VideoCompositionDemoViewStatesStore()
        self.stateStore = stateStore
        self.interactor = VideoCompositionDemoViewInteractor(displayStateStore: stateStore)
    }

    var body: some View {
        VStack {
            makeDemoVideoView()
            makeDemoOptionPicker()
        }
    }
}

// MARK: - Private functions
extension VideoCompositionDemoView {

    // MARK: - ViewBuilders

    @ViewBuilder
    private func makeDemoVideoView() -> some View {
        if let player = stateStore.currentPlayer {
            VideoPlayer(player: player)
                .onAppear {
                    player.seek(to: .zero)
                    player.play()
                }
        } else {
            Text("Please select a demo")
        }
    }

    @ViewBuilder
    private func makeDemoOptionPicker() -> some View {
        ForEach(stateStore.demoOptions) { option in
            Text(option.name)
                .padding()
                .background(
                    option == stateStore.currentOption
                    ? Color.blue
                    : Color.clear
                )
                .foregroundColor(
                    option == stateStore.currentOption
                    ? Color.white
                    : Color.black
                )
                .onTapGesture {
                    Task {
                        await interactor.updateCurrentDemo(with: option)
                    }
                }
                .modifier(
                    RoundedOptionCellModifier(
                        isHighlighted: option == stateStore.currentOption,
                        cornerRadius: 30
                    )
                )
        }
    }
}

#Preview {
    VideoCompositionDemoView()
}
