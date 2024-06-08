//
//  WatermarkDemoVideoCompositor.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/11/28.
//

import UIKit
import AVFoundation
import MetalKit

private struct WatermarkDemoError: Error {
    let description: String
}

final class WatermarkDemoVideoCompositor: NSObject, AVVideoCompositing {

    // MARK: AVVideoCompositing properties

    var sourcePixelBufferAttributes: [String : Any]? = [
        (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
    ]

    var requiredPixelBufferAttributesForRenderContext: [String : Any] = [
        (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
    ]

    // MARK: Private properties

    // The primary part for the part III demo
    private var metalRenderer = WatermarkMetalRenderer()

    // Dispatch Queue used to issue custom compositor rendering work requests.
    private var renderingQueue = DispatchQueue(label: "com.videoCompositionDemo.renderingQueue")

    // MARK: AVVideoCompositing functions

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        // The renderContext won't change in our demo case
    }

    /*
     - This delegate function will be invoke for every frame
     - If you intend to finish rendering the frame after your handling of this message returns, you must retain the instance of AVAsynchronousVideoCompositionRequest until after composition is finished.
     - If the custom compositor's implementation of -startVideoCompositionRequest: returns without finishing the composition immediately, it may be invoked again with another composition request before the prior request is finished; therefore in such cases the custom compositor should be prepared to manage multiple composition requests.
     - The above description is also the reason why most of the libs, which do this with Metal, will put this procedure into a queue, and make the procedure to be cancelable.
     */
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        renderingQueue.async {
            do {
                let result = try self.newRenderedPixelBufferForRequest(asyncVideoCompositionRequest)
                asyncVideoCompositionRequest.finish(withComposedVideoFrame: result)
            } catch {
                asyncVideoCompositionRequest.finish(with: error)
            }
        }
    }
}

// MARK: - Private functions
extension WatermarkDemoVideoCompositor {

    private func newRenderedPixelBufferForRequest(_ request: AVAsynchronousVideoCompositionRequest) throws -> CVPixelBuffer {

        guard let instruction = request.videoCompositionInstruction as? WatermarkDemoCompositionInstruction else {
            let error: VideoCompositingError = .incorrectVideoCompositionInstructionType(
                currentInstruction: request.videoCompositionInstruction
            )
            throw error
        }
        guard let outputBuffer: CVPixelBuffer = request.renderContext.newPixelBuffer() else {
            let error: VideoCompositingError = .generateOutputPixelBufferFailed
            throw error
        }

        let sources = instruction
            .videoLayerInstructions
            .compactMap { layerInstruction -> CVPixelBuffer? in
                guard case let .videoTrack(information) = layerInstruction.instructionType else {
                    return nil
                }
                return request.sourceFrame(
                    byTrackID: information.trackID
                )
            }

        let watermarkImage = { () -> UIImage? in
            for layerInstruction in instruction.videoLayerInstructions {
                guard
                    case let .watermarkImage(image) = layerInstruction.instructionType,
                    layerInstruction.timeRange.containsTime(request.compositionTime)
                else {
                    continue
                }
                return image
            }
            return nil
        }()

        let factor = Float(request.compositionTime.seconds)
        metalRenderer?.opacity = 0.25 * (1 + sin(2 * .pi * factor))

        metalRenderer?.renderPixelBuffer(
            outputBuffer,
            sources: sources,
            watermark: watermarkImage
        )
        return outputBuffer
    }
}
