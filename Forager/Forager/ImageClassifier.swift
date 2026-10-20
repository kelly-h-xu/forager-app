//
//  ImageClassifier.swift
//  Forager
//
//  Created by Kelly Xu on 2/28/26.
//

import CoreML
import Vision
import UIKit

class ImageClassifier {
    static let shared = ImageClassifier()
    
    private let model: VNCoreMLModel
    
    private init() {
        let mlModel = try! ForagerClassifier(configuration: MLModelConfiguration()).model
        self.model = try! VNCoreMLModel(for: mlModel)
    }
    
    func classify(image: UIImage) async -> ClassificationResult {
        await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: ClassificationResult(label: "Unknown", confidence: 0))
                return
            }
            
            let request = VNCoreMLRequest(model: model) { request, error in
                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    continuation.resume(returning: ClassificationResult(label: "Unknown", confidence: 0))
                    return
                }
                
                continuation.resume(returning: ClassificationResult(
                    label: topResult.identifier,
                    confidence: Double(topResult.confidence)
                ))
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}

