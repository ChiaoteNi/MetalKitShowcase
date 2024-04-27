//
//  DemoImageProvider.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/16.
//

import UIKit

enum DemoImageProvider {

    static func fetchSourceImages() -> [UIImage] {
        fetchImagesFromBundle("SourceImages") ?? []
    }

    static func fetchBlendImages() -> [UIImage] {
        // most of the blend images are from here: https://tigers-stock.deviantart.com
        fetchImagesFromBundle("BlendImages") ?? []
    }

    private static func fetchImagesFromBundle(_ bundleName: String) -> [UIImage]? {
        guard
            let bundleURL = Bundle.main.url(forResource: bundleName, withExtension: "bundle"),
            let imageBundle = Bundle(url: bundleURL)
        else {
            return nil
        }
        let imageNames = imageBundle.paths(forResourcesOfType: "png", inDirectory: nil)
        return imageNames.compactMap { UIImage(contentsOfFile: $0) }
    }
}
