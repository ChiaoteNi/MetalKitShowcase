//
//  ParallelPlayWithMetalDemo.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/11/28.
//

import Foundation
import AVFoundation

struct ParallelPlayWithMetalTrackContext: TrackContextProtocol {
    let asset: AVAsset
    let index: Int
    let preferredTimeRange: CMTimeRange
    let preferredStartTime: CMTime
    let preferredTrackID: CMPersistentTrackID
}

final class ParallelVideoPlayDemo: VideoCompositingDemoItemMaking {
    // VideoCompositingDemoItemMaking
    var id: String { "demo_video_editing_parallel" }
    var name: String { "Parallel Video Playing" }

    typealias TrackContext = ParallelPlayWithMetalTrackContext

    func makePlayerItem() async -> AVPlayerItem? {
        // 1. Define the time range for playing of each video asset
        let trackContexts: [TrackContext] = makeTrackContexts()
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

extension ParallelVideoPlayDemo {

    private func makeTrackContexts() -> [TrackContext] {
        let assets = [
            AVAsset(for: "meeting_2", withExtension: "mp4"),
            AVAsset(for: "meeting_3", withExtension: "mp4"),
            AVAsset(for: "meeting_4", withExtension: "mp4"),
            AVAsset(for: "meeting_5", withExtension: "mp4"),
        ]

        let makeCMTime: (_ seconds: Double) -> CMTime = { seconds in
            CMTime(
                seconds: seconds,
                preferredTimescale: 30
            )
        }

        let (assetTracks): ([ParallelPlayWithMetalTrackContext]) = assets
            .compactMap { $0 }
            .enumerated()
            .map { enumeratedElement in
                let index = enumeratedElement.offset
                let asset = enumeratedElement.element

                let timeRange = CMTimeRange(
                    start: .zero,
                    duration: makeCMTime(Double(index + 2))
                )
                let trackContext = ParallelPlayWithMetalTrackContext(
                    asset: asset,
                    index: index,
                    preferredTimeRange: timeRange,
                    preferredStartTime: .zero,
                    preferredTrackID: CMPersistentTrackID(index + 1)
                )
                return trackContext
            }

        return assetTracks
    }

    // MARK: - About making VideoComposition

    private func makeComposition(with trackContexts: [TrackContextProtocol]) async -> AVMutableComposition {
        let composition = AVMutableComposition()
        do {
            for trackContext in trackContexts {
                // In the general case, we need to get audio tracks from the asset as well.
                // However, since we'll focus on rendering with Metal Shader in this demo,
                // I'll ignore the steps of registering audios to audio tracks
                // Please check this repo if you have a interest of this part:
                // https://github.com/ChiaoteNi/AVCompositionDemo
                let videoAssetTracks = try await trackContext.asset.loadTracks(withMediaType: .video)
                // This only loads the first video track from the asset,
                // although the asset may contain multiple tracks depending on the video used
                guard let videoAssetTrack = videoAssetTracks.first else {
                    continue
                }

                let compositionTrack: AVMutableCompositionTrack? = {
                    // In case the track is already created, use that track.
                    if let track = composition.track(withTrackID: trackContext.preferredTrackID) {
                        return track
                    }
                    // Otherwise, add a mutableTrack with the specific trackID into the composition.
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
            // create instructions to attach them to the composition
            guard let instruction = makeInstruction(with: trackContexts) else {
                return nil
            }
            let composition = AVMutableVideoComposition()
            composition.customVideoCompositorClass = ParallelPlayWithMetalVideoCompositor.self // Setup a custom type videoComposition here
            composition.instructions = [instruction]
            composition.renderSize = Constants.demoVideoSize // It's required.
            composition.frameDuration = CMTime(seconds: 1/30, preferredTimescale: 30) // It's required.
            return composition
        }()

        return videoComposition
    }

    private func makeInstruction(with trackContexts: [TrackContext]) -> AVVideoCompositionInstructionProtocol? {

        let result: (CMTimeRange, [ParallelPlayWithMetalLayerInstruction]) = trackContexts
            .reduce(into:(.zero, [])) { partialResult, trackContext in

                let currentTimeRange = partialResult.0
                let timeRange = CMTimeRange(
                    start: trackContext.preferredStartTime,
                    duration: trackContext.preferredTimeRange.duration
                )
                partialResult.0 = CMTimeRangeGetUnion(
                    currentTimeRange,
                    otherRange: timeRange
                )

                let instruction = ParallelPlayWithMetalLayerInstruction(
                    trackID: trackContext.preferredTrackID,
                    startTime: trackContext.preferredStartTime,
                    timeRange: trackContext.preferredTimeRange,
                    index: trackContext.index
                )
                partialResult.1.append(instruction)
            }

        let videoInstruction = ParallelPlayWithMetalCompositionInstruction(
            videoLayerInstructions: result.1,
            timeRange: result.0
        )
        return videoInstruction
    }
}

// MARK: - Constants and Util functions

private enum Constants {

    // ⬇️ Just to easier make the demo and make the demo more focused on the video composition.
    //    Generally, you'll need to get the size by yourself in run-time but not hardcode it as a constant.
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
