//
//  Sequence + Async.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/21.
//

import Foundation

extension Sequence {

    func asyncMap<ElementOfResult>(
        _ transform: @escaping (Element) async throws -> ElementOfResult
    ) async rethrows -> [ElementOfResult] {

        var results = [ElementOfResult]()
        for element in self {
            let result = try await transform(element)
            results.append(result)
        }
        return results
    }
}
