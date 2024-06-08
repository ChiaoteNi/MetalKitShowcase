//
//  VideoCompositionDemoViewInteractor.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/20.
//

import Foundation
import AVFoundation

protocol VideoCompositionDemoViewStatesStoring {
    func updateCurrentPlayerItem(_ playerItem: AVPlayerItem?)
    func updateDemoOptions(_ options: [VideoCompositionDemoOption])
}

final class VideoCompositionDemoViewInteractor {

    private let displayStateStore: VideoCompositionDemoViewStatesStoring

    private var currentDemo: VideoCompositionDemoOption?
    private let demoOptions: [VideoCompositionDemoOption]

    init(displayStateStore: VideoCompositionDemoViewStatesStoring) {
        self.displayStateStore = displayStateStore
        let options: [VideoCompositionDemoOption] = [
            VideoCompositionDemoOption(demoPlayerItemMaker: ParallelVideoPlayDemo()),
            VideoCompositionDemoOption(demoPlayerItemMaker: WatermarkDemo())
        ]
        self.demoOptions = options
        displayStateStore.updateDemoOptions(options)
    }

    func updateCurrentDemo(with demoOption: VideoCompositionDemoOption) async {
        guard let demoOption = demoOptions.first(where: { $0.id == demoOption.id }) else {
            return
        }
        guard let playerItem = await demoOption.demoPlayerItemMaker.makePlayerItem() else {
            return
        }
        displayStateStore.updateCurrentPlayerItem(playerItem)
    }
}
