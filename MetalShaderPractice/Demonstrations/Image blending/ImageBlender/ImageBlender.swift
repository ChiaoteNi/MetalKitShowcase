//
//  ImageBlender.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/15.
//

import UIKit
import MetalKit
import simd

final class ImageBlender {

    enum BlendMode {
        case simpleBlend // just blend the image with the alpha value
        case screenBlend // blend the image with the screen blend mode

        var fragmentFunctionName: String {
            switch self {
            case .simpleBlend:
                return "simple_blend_fragment_func"
            case .screenBlend:
                return "screen_blend_fragment_func"
            }
        }
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

    func createBlendedImage(
        sourceImage: UIImage,
        blendImage: UIImage,
        blendMode: BlendMode,
        opacity: Float
    ) -> UIImage? {
        guard
            let sourceTexture = makeTexture(with: sourceImage),
            let overlayTexture = makeTexture(with: blendImage),
            let outputTexture = render(
                sourceTexture: sourceTexture,
                blendTexture: overlayTexture,
                blendMode: blendMode,
                opacity: opacity
            )
        else {
            return nil
        }

        let outputImage = outputTexture.makeUIImage()
        return outputImage
    }

    func render(
        sourceTexture: MTLTexture,
        blendTexture: MTLTexture,
        blendMode: BlendMode,
        opacity: Float
    ) -> MTLTexture? {
        guard let outputTexture = makeOutputTexture() else {
            return nil
        }

        // Set up a render pass descriptor for configuring the rendering operations.
        let renderPassDescriptor = MTLRenderPassDescriptor()
        // Attach the output texture to the first color attachment point.
        // This attachment will store the rendered output from the fragment shader.
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        // Configure the action to load the existing content of the attachment.
        // This is useful for operations like blending where the previous content needs to be preserved.
        renderPassDescriptor.colorAttachments[0].loadAction = .load

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "screen_blend_vertex_func")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: blendMode.fragmentFunctionName)
        // Set the pixel format for the color attachment to match the output texture format.
        pipelineDescriptor.colorAttachments[0].pixelFormat = .rgba8Unorm

        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
            let pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        else {
            return nil
        }

        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setVertexBuffer(makeVertexBuffer(), offset: 0, index: 0)

        commandEncoder.setFragmentTexture(sourceTexture, index: 0)
        commandEncoder.setFragmentTexture(blendTexture, index: 1)

        let sampler = makeSampler()
        commandEncoder.setFragmentSamplerState(sampler, index: 0)

        var opacity = opacity
        commandEncoder.setVertexBytes(
            &opacity,
            length: MemoryLayout<Float>.size,
            index: 1
        )

        commandEncoder.drawPrimitives(
            // .point
            // Draws each vertex as an individual point.
            // Use case: Suitable for drawing point clouds,
            // such as particle systems or point markers.

            // .line
            // Pairs of vertices are treated as individual line segments.
            // For example, vertices 0 and 1 form one line, and vertices 2 and 3 form another.
            // Use case: Useful for drawing wireframe models or any graphics where straight line connections are needed.

            // .lineStrip
            // Connects vertices in sequence to form a continuous line.
            // Vertex 0 connects to vertex 1, vertex 1 connects to vertex 2, and so on.
            // Use case: Ideal for drawing continuous line paths, like graphs or traces.

            // .triangle
            // Groups of three vertices are treated as individual triangles.
            // For example, vertices 0, 1, and 2 form one triangle, and vertices 3, 4, and 5 form another.
            // Use case: Used when rendering a set of disconnected triangles, where each triangle is independent.

            // .triangleStrip
            // Connects vertices to form a strip of adjoining triangles.
            // The first triangle is formed by vertices 0, 1, and 2; the second by vertices 2, 1, and 3 (note that the order of vertices may vary by API).
            // Use case: Efficient for rendering a mesh of triangles sharing edges, commonly used for terrain or other contiguous surfaces.
            type: .triangleStrip,
            vertexStart: 0, // Start from the first vertex in the buffer.
            vertexCount: 4  // Use four vertices to draw two connected triangles forming a rectangle.
        )
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return outputTexture
    }
}

// MARK: - Private functions
extension ImageBlender {

    private func makeSampler() -> MTLSamplerState? {
        let samplerDescriptor = MTLSamplerDescriptor()
        // Sets the filtering method when the texture is minified (scaled down).
        // `.linear` uses linear filtering to average the texture pixels around the sample point.
        samplerDescriptor.minFilter = .linear
        // Sets the filtering method when the texture is magnified (scaled up).
        // `.linear` uses linear filtering to smooth the texture during magnification.
        samplerDescriptor.magFilter = .linear
        // Defines the behavior when sampling texture coordinates outside the [0.0, 1.0] range along the S (horizontal) axis.
        // `.clampToEdge` extends the texture's edge colors when coordinates are out of bounds.
        samplerDescriptor.sAddressMode = .clampToEdge
        // Defines the behavior when sampling texture coordinates outside the [0.0, 1.0] range along the T (vertical) axis.
        // `.clampToEdge` behaves like sAddressMode, preventing tiling artifacts along the texture's edges.
        samplerDescriptor.tAddressMode = .clampToEdge
        return device.makeSamplerState(descriptor: samplerDescriptor)
    }
    // MARK: - Texture

    private func makeTexture(with image: UIImage) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: device)
        guard
            let cgImage = image.cgImage,
            let texture = try? textureLoader.newTexture(cgImage: cgImage, options: nil)
        else {
            return nil
        }
        return texture
    }

    private func makeOutputTexture() -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,   // Specifies the pixel format. RGBA with 8 bits for each component, normalized.
            width: 2000,
            height: 1500,
            mipmapped: false            // Indicates that no mipmaps should be generated for this texture.
        )

        // Specifies the intended usage of the texture. This affects which GPU optimizations are applied.
        // There are 5 usages:
        /*
         .shaderRead:
         Can be read by shader programs. 
         This is the most common usage, suitable for using the texture as input data.

         .shaderWrite:
         Can be written to by shader programs. 
         This is typically used for image or data processing tasks where compute shaders modify the texture after performing some image processing operations.

         .renderTarget:
         Can be used as a render target, meaning it can be bound to the output of the rendering pipeline. 
         This is particularly useful when rendering to a texture or performing off-screen rendering.

         .pixelFormatView:
         Can be used to create texture views with a different pixel format but the same storage allocation. 
         This allows developers to reinterpret the same texture data in a different format, such as reinterpreting RGBA8 as R32.

         .shaderAtomic: (iOS 17)
         The texture supports atomic operations in shaders.
         This usage is crucial for tasks that require synchronization or complex data manipulation by shaders,
         ensuring that operations such as increments or comparisons are performed atomically.

         */
        textureDescriptor.usage = [.shaderRead, .renderTarget] // Texture can be read by shaders and used as a render target.

        // Create and return the texture from the GPU device using the defined descriptor.
        return device.makeTexture(descriptor: textureDescriptor)

    }

    private func makeVertexBuffer() -> MTLBuffer? {
        // Square vertices with texture coordinates
        struct Vertex {
            var position: (Float, Float)
            var texCoord: (Float, Float)
        }
        // position: position of vertices
        // texCoord: texture coordinates, which are used to map vertices to corresponding points on a texture.
        //           Texture coordinates define how to map a texture image onto a geometric shape
        // The values are designed for the triangleStrip type
        let vertices: [Vertex] = [
            Vertex(position: (-1, -1), texCoord: (0, 0)),   // Bottom left
            Vertex(position: (1, -1), texCoord: (1, 0)),    // Bottom right
            Vertex(position: (-1, 1), texCoord: (0, 1)),    // Top left
            Vertex(position: (1, 1), texCoord: (1, 1)),     // Top right
        ]
        return device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<Vertex>.stride,
            options: []
        )
    }
}
