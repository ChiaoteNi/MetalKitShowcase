//
//  TrackContext.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/10/15.
//

import Foundation
import AVFoundation

protocol TrackContextProtocol {
    var asset: AVAsset { get }
    var preferredTimeRange: CMTimeRange { get }
    var preferredTrackID: CMPersistentTrackID { get }
}
