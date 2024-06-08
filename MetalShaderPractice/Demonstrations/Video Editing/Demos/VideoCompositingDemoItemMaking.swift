//
//  VideoCompositingDemoItemMaking.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/20.
//

import Foundation
import AVFoundation

protocol VideoCompositingDemoItemMaking: Hashable, AnyObject {
    var id: String { get }
    var name: String { get }
    func makePlayerItem() async -> AVPlayerItem?
}

// MARK: Hashable
extension VideoCompositingDemoItemMaking {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
