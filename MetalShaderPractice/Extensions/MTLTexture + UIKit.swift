//
//  MTLTexture + UIKit.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/15.
//

import UIKit
import MetalKit

extension MTLTexture {

    func makeUIImage() -> UIImage? {
        guard
            let ciImage = CIImage(mtlTexture: self),
            // TODO: leave a comment for this
            let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent)
        else {
            return nil
        }
//        return UIImage(ciImage: ciImage)
        return UIImage(cgImage: cgImage)
    }
}
