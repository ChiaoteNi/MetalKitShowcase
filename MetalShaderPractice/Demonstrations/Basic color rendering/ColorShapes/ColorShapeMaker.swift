//
//  ColorShapeMaker.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/14.
//

import UIKit
import MetalKit
import simd

private struct Vertex {
    let position: vector_float4 // xyzw
    let color: vector_float4    // rgba
}

final class ColorShapeMaker {

    enum Shapes {
        case circle
        case triangle
        case square
        case squareForTriangleStrip
    }

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device
        // The command queue is used to create command buffers, which are used to encode commands that the GPU will execute
        // Also, it will guarantee to execute the command buffers under thread-safe
        self.commandQueue = device.makeCommandQueue()!
        // Load all shaders from the default library.
        // The compiler will compile the shaders and store them in the default library.
        self.library = device.makeDefaultLibrary()!
    }

    func makeShapeImage(
        shape: Shapes,
        color: UIColor?,
        // I make the drawType a parameter to simplify the demonstration of differences for each type, making it easier to understand.
        // However, normally, would set it directly when invoking drawPrimitives, rather than passing it as a parameter.
        drawType: MTLPrimitiveType
    ) -> UIImage? {

        guard let texture = makeTexture(shape: shape, color: color, drawType: drawType) else {
            return nil
        }
        let image = texture.makeUIImage()
        return image
    }
}

// MARK: - Private functions
extension ColorShapeMaker {

    private func makeTexture(
        shape: Shapes,
        color: UIColor?,
        // I make the drawType a parameter to simplify the demonstration of differences for each type, making it easier to understand.
        // However, normally, would set it directly when invoking drawPrimitives, rather than passing it as a parameter.
        drawType: MTLPrimitiveType
    ) -> MTLTexture? {
        // Step 1: Create a vertex buffer with the vertex data for the shape
        let points = makePoints(for: shape)
        let vertexData = makeVertexData(with: points, color: color)
        let vertexBuffer = device.makeBuffer(
            bytes: vertexData,
            length: MemoryLayout<Vertex>.stride * points.count,
            options: []
        )

        // Step 2: Create a render pipeline state
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        // The vertex function and fragment function are the entry points for the vertex and fragment shaders
        // Also, since the compiler will compile the shaders and store them in the default library,
        // when we have multiple shader files, we shouldn't use the same name for the functions.
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "color_shape_vertex_point_func")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "color_shape_fragment_color_func")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Step 3: Create a texture descriptor
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: 300,
            height: 300,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .renderTarget]

        // Step 4: Create a texture from the texture descriptor
        let texture = device.makeTexture(descriptor: textureDescriptor)!

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
//        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0.5, 1) // when loadAction is .clear

        // Step 5: Create a command buffer and encoder
        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return nil
        }

        // Step 6: Set the render pipeline state and vertex buffer
        let pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        renderEncoder.setRenderPipelineState(pipelineState)

        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        // Step 7: Draw the shape
        renderEncoder.drawPrimitives(
            // Switch the following 2 types, and see the difference between line and filled triangle
            /*
             line:           1,2,3,4 ➡️ 1->2, 3->4
             lineStrip:      1,2,3,4 ➡️ 1->2->3->4
             triangle:       1,2,3,4 ➡️ 1->2->3, 4
             triangleStrip:  1,2,3,4 ➡️ 1->2->3, 2->3->4
             */
//            type: .line,
//            type: .triangle,
//            type: .triangleStrip,
            type: drawType,
            vertexStart: 0,
            vertexCount: points.count
        )

        // Step 8: End encoding and commit the command buffer
        renderEncoder.endEncoding()
        commandBuffer.commit()

        commandBuffer.waitUntilCompleted()
        return texture
    }

    // MARK: VertexData for shapes

    private func makeVertexData(with points: [CGPoint], color: UIColor?) -> [Vertex] {
        let locations: [vector_float4] = points.map {
            vector_float4(Float($0.x), Float($0.y), 0, 1)
        }

        let strokeColor = { () -> SIMD4<Float>? in
            guard let color else { return nil }

            return SIMD4<Float>(
                Float(color.redComponent),
                Float(color.greenComponent),
                Float(color.blueComponent),
                Float(color.alphaComponent)
            )
        }()

        let vertexData = locations.map {
            Vertex(
                position: $0,
                // Returns random colors to demonstrate how the fragment function works between two end points with different colors.
                color: strokeColor ?? .randomColor()
            )
        }
        return vertexData
    }

    private func makePoints(for shape: Shapes) -> [CGPoint] {
        switch shape {
        case .circle:
            return makeCirclePoints()
        case .triangle:
            return makeTrianglePoints()
        case .square:
            return makeSquarePoints()
        case .squareForTriangleStrip:
            return makeSquarePointsForTriangleStrip()
        }
    }

    private func makeCirclePoints() -> [CGPoint] {
        /*
        This result only works for rendering with the lineStrip MTLPrimitiveType.
        When it comes to the triangle, the points can't be used directly.
        */
        let radius: CGFloat = 0.5
        let center = CGPoint(x: 0.5, y: 0.5)
        let points = stride(from: 0, to: 2 * .pi, by: .pi / 100).map {
            CGPoint(x: center.x + radius * cos($0), y: center.y + radius * sin($0))
        }
        return points
    }

    private func makeTrianglePoints() -> [CGPoint] {
        // Comparing the result image, we can see that the coordinate system in Metal is different from that in UIKit.
        return [
            CGPoint(x: -0.9, y: 0.9),
            CGPoint(x: -0.9, y: -0.9),
            CGPoint(x: 0.9, y: -0.9)
        ]
    }

    // Case 1: All required endpoints - compatible with both .triangle and .triangleStrip.
    private func makeSquarePoints() -> [CGPoint] {
        return [
            // The bottom-left triangle
            CGPoint(x: -0.9, y: 0.9),
            CGPoint(x: -0.9, y: -0.9),
            CGPoint(x: 0.9, y: -0.9),
            // The top-right triangle
            // TODO: leave a comment here -> mark the code
            CGPoint(x: -0.9, y: 0.9),
            CGPoint(x: 0.9, y: 0.9),
            CGPoint(x: 0.9, y: -0.9),
        ]
    }

    // Case 2: Only four points - works exclusively with .triangleStrip.
    private func makeSquarePointsForTriangleStrip() -> [CGPoint] {
        return [
            CGPoint(x: -0.9, y: 0.9),
            CGPoint(x: 0.9, y: 0.9),
            CGPoint(x: -0.9, y: -0.9),
            CGPoint(x: 0.9, y: -0.9),
        ]
    }
}

// MARK: - Helper functions

private extension UIColor {
    var redComponent: CGFloat {
        var red: CGFloat = 0
        getRed(&red, green: nil, blue: nil, alpha: nil)
        return red
    }

    var greenComponent: CGFloat {
        var green: CGFloat = 0
        getRed(nil, green: &green, blue: nil, alpha: nil)
        return green
    }

    var blueComponent: CGFloat {
        var blue: CGFloat = 0
        getRed(nil, green: nil, blue: &blue, alpha: nil)
        return blue
    }

    var alphaComponent: CGFloat {
        var alpha: CGFloat = 0
        getRed(nil, green: nil, blue: nil, alpha: &alpha)
        return alpha
    }
}

private extension SIMD4 where Scalar == Float {

    static func randomColor() -> SIMD4<Float> {
        SIMD4(
            Float.random(in: 0...1),
            Float.random(in: 0...1),
            Float.random(in: 0...1),
            Float.random(in: 0.8...1)
        )
    }
}
