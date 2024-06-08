//
//  VideoCompositionDemoOption.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/20.
//

import Foundation

struct VideoCompositionDemoOption: Identifiable, Hashable {
    var id: String { demoPlayerItemMaker.id }
    var name: String { demoPlayerItemMaker.name }
    let demoPlayerItemMaker: any VideoCompositingDemoItemMaking

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: VideoCompositionDemoOption, rhs: VideoCompositionDemoOption) -> Bool {
        lhs.id == rhs.id
    }
}
