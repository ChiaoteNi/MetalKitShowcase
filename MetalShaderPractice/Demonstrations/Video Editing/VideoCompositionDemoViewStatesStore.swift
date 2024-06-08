//
//  VideoCompositionDemoViewStatesStore.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/20.
//

import Foundation
import AVFoundation

@Observable
final class VideoCompositionDemoViewStatesStore: VideoCompositionDemoViewStatesStoring, ObservableObject {

    var currentOption: VideoCompositionDemoOption?

    private(set) var currentPlayer: AVPlayer?
    private(set) var demoOptions: [VideoCompositionDemoOption] = []

    func updateCurrentPlayerItem(_ playerItem: AVPlayerItem?) {
        currentPlayer = AVPlayer(playerItem: playerItem)
    }

    func updateDemoOptions(_ options: [VideoCompositionDemoOption]) {
        demoOptions = options
    }
}
