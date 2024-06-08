//
//  WatermarkDemoCompositionInstruction.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/11/28.
//

import UIKit
import AVFoundation

enum WatermarkVideoInstructionType {
    case watermarkImage(UIImage)
    case videoTrack(information: WatermarkDemoVideoTrackInformation)
}

struct WatermarkDemoLayerInstruction {
    let instructionType: WatermarkVideoInstructionType
    let timeRange: CMTimeRange
}

struct WatermarkDemoVideoTrackInformation {
    let trackID: CMPersistentTrackID
}

// It's the way that allow us to attach required information to the VideoComposition,
// then retrieve them back in our customized VideoCompositor.
final class WatermarkDemoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {

    var videoLayerInstructions: [WatermarkDemoLayerInstruction]

    /// Indicates the timeRange during which the instruction is effective.
    /// Note requirements for the timeRanges of instructions described in connection with AVVideoComposition's instructions key above.
    var timeRange: CMTimeRange
    /// If NO, indicates that post-processing should be skipped for the duration of this instruction.
    var enablePostProcessing: Bool = true
    /// If YES, rendering a frame from the same source buffers and the same composition instruction at 2 different compositionTime may yield different output frames.
    /// If NO, 2 such compositions would yield the same frame.
    /// The media pipeline may me able to avoid some duplicate processing when containsTweening is NO
    var containsTweening: Bool = true
    /// List of video track IDs required to compose frames for this instruction.
    /// If the value of this property is nil, all source tracks will be considered required for composition
    var requiredSourceTrackIDs: [NSValue]?
    /// If for the duration of the instruction, the video composition result is one of the source frames, this property should
    /// return the corresponding track ID. The compositor won't be run for the duration of the instruction and the proper source
    /// frame will be used instead. The dimensions, clean aperture and pixel aspect ratio of the source buffer will be matched to the required values automatically
    var passthroughTrackID: CMPersistentTrackID

    init(
        videoLayerInstructions: [WatermarkDemoLayerInstruction],
        timeRange: CMTimeRange,
        requiredSourceTrackIDs: [NSValue]? = nil,
        passthroughTrackID: CMPersistentTrackID? = nil
    ) {
        self.videoLayerInstructions = videoLayerInstructions
        self.timeRange = timeRange
        self.requiredSourceTrackIDs = requiredSourceTrackIDs
        self.passthroughTrackID = passthroughTrackID ?? kCMPersistentTrackID_Invalid
    }
}

