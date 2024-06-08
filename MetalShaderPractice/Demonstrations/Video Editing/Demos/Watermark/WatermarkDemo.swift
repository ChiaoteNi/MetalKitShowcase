//
//  WatermarkDemo.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/11/28.
//

import UIKit
import AVFoundation

struct WatermarkDemoTrackContext: TrackContextProtocol {
    let asset: AVAsset
    let preferredTimeRange: CMTimeRange
    let preferredTrackID: CMPersistentTrackID
}

final class WatermarkDemo: VideoCompositingDemoItemMaking {
    // VideoCompositingDemoItemMaking
    var id: String { "demo_video_editing_watermark" }
    var name: String { "Video Watermark" }

    typealias TrackContext = WatermarkDemoTrackContext

    func makePlayerItem() async -> AVPlayerItem? {
        // 1. Define the time range for playing of each video asset
        let trackContexts: [TrackContext] = await makeTrackContexts()
        guard !trackContexts.isEmpty else { return nil }

        // 2. Create an AVComposition and insert all video tracks extracted from the asset into the composition.
        let composition: AVComposition = await makeComposition(with: trackContexts)
        // 3. Create instructions to attach the tracks' information to our customized VideoCompositor.
        let videoComposition: AVVideoComposition? = makeVideoComposition(with: trackContexts)

        // 4. Create a player item with our customized composition. (Basically, the AVComposition is an AVAsset as well)
        return AVPlayerItem(asset: composition)
            .set(\.videoComposition, to: videoComposition)
    }
}

extension WatermarkDemo {

    private func makeTrackContexts() async -> [TrackContext] {
        let assets = [
            AVAsset(for: "seal", withExtension: "MOV"),
            AVAsset(for: "Disney", withExtension: "MOV")
        ]

        var startTime: CMTime = .zero
        let assetTracks: [WatermarkDemoTrackContext] = await assets
            .compactMap { $0 }
            .enumerated()
            .asyncMap { enumeratedElement in
                let index = enumeratedElement.offset
                let asset = enumeratedElement.element

                let duration = await {
                    if let assetDuration = try? await asset.load(.duration) {
                        // Play each asset sequentially, back to back.
                        return assetDuration
                    } else {
                        return CMTime(seconds: 2, preferredTimescale: 60)
                    }
                }()
                let timeRange = CMTimeRange(
                    start: startTime,
                    duration: duration//CMTime(seconds: 2, preferredTimescale: 30)
                )
                startTime = timeRange.end//startTime + timeRange.duration

                let trackContext = WatermarkDemoTrackContext(
                    asset: asset,
                    preferredTimeRange: timeRange,
                    preferredTrackID: CMPersistentTrackID(index + 1)
                )
                return trackContext
            }

        return assetTracks
    }

    // MARK: - About making VideoComposition

    // Please ignore this function if you have seen the implementation of ParallelVideoPlayDemo
    // They're 100% the same, and this function isn't the important
    private func makeComposition(with trackContexts: [TrackContextProtocol]) async -> AVMutableComposition {
        let composition = AVMutableComposition()
        do {
            for trackContext in trackContexts {
                // I'll skip the steps of registering audios to audio tracks here,
                // since I want to make this demonstration to focus on rendering with Metal Shader,
                // Please check this repo if you have a interest of the remaining part:
                // https://github.com/ChiaoteNi/AVCompositionDemo
                let videoAssetTracks = try await trackContext.asset.loadTracks(withMediaType: .video)
                // This only loads the first video track from the asset,
                // although the asset may contain multiple tracks depending on the video used
                guard let videoAssetTrack = videoAssetTracks.first else {
                    continue
                }

                let compositionTrack: AVMutableCompositionTrack? = {
                    // If the track has already been created, reuse that track.
                    if let track = composition.track(withTrackID: trackContext.preferredTrackID) {
                        return track
                    }
                    // If not, add a mutable track with the specified trackID to the composition.
                    return composition.addMutableTrack(
                        withMediaType: .video,
                        // Pass kCMPersistentTrackID_Invalid to automatically generate an appropriate identifier by the systems.
                        preferredTrackID: trackContext.preferredTrackID
                    )
                }()

                try compositionTrack?.insertTimeRange(
                    trackContext.preferredTimeRange,
                    of: videoAssetTrack,
                    at: trackContext.preferredTimeRange.start
                )
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
        return composition
    }

    private func makeVideoComposition(with trackContexts: [TrackContext]) -> AVVideoComposition? {
        guard !trackContexts.isEmpty else {
            return nil
        }

        let videoComposition: AVVideoComposition? = {
            // Create instructions to attach them to the composition.
            guard let instruction = makeInstruction(with: trackContexts) else {
                return nil
            }
            let composition = AVMutableVideoComposition()
            composition.customVideoCompositorClass = WatermarkDemoVideoCompositor.self // Setup a custom type videoComposition here
            composition.instructions = [instruction]
            // composition.animationTool <- We can use this to achieve our goal as well, but in this
            composition.renderSize = Constants.demoVideoSize // It's required.
            composition.frameDuration = CMTime(seconds: 1/30, preferredTimescale: 30) // It's required.
            return composition
        }()

        return videoComposition
    }

    private func makeInstruction(with trackContexts: [TrackContext]) -> AVVideoCompositionInstructionProtocol? {

        let result: (timeRange: CMTimeRange, instructions: [WatermarkDemoLayerInstruction]) = trackContexts
            .reduce(into:(.zero, [])) { partialResult, trackContext in

                let currentTimeRange = partialResult.timeRange
                let timeRange = trackContext.preferredTimeRange
                partialResult.timeRange = CMTimeRangeGetUnion(
                    currentTimeRange,
                    otherRange: timeRange
                )

                let instruction = WatermarkDemoLayerInstruction(
                    instructionType: .videoTrack(information: WatermarkDemoVideoTrackInformation(trackID: trackContext.preferredTrackID)),
                    timeRange: trackContext.preferredTimeRange
                )
                partialResult.instructions.append(instruction)
            }

        let watermarkImage = retrieveWatermarkImage()
        let watermarkInstruction = WatermarkDemoLayerInstruction(
            instructionType: .watermarkImage(watermarkImage),
            timeRange: result.timeRange
        )

        let videoInstruction = WatermarkDemoCompositionInstruction(
            videoLayerInstructions: [watermarkInstruction] + result.instructions,
            timeRange: result.timeRange
        )
        return videoInstruction
    }

    private func retrieveWatermarkImage() -> UIImage {
        UIImage(named: "watermark")!
    }
}

// MARK: - Constants and Util functions

private enum Constants {

    // ⬇️ Just to easier make the demo and make the demo more focused on the video composition.
    //    Generally, you'll need to get the size by yourself in run-time but not hardcode it as a constant.
    //    ex: let size = await asset.load(.naturalSize)
    static var demoVideoSize: CGSize {
        CGSize(width: 1920, height: 1080)
    }
}

private extension CMTime {
    static func - (_ lhs: CMTime, _ rhs: Double) -> CMTime {
        CMTime(
            seconds: lhs.seconds - rhs,
            preferredTimescale: lhs.timescale
        )
    }
}
