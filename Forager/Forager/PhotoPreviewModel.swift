//
//  PhotoPreviewModel.swift
//  Forager
//
//  Created by Kelly Xu on 2/28/26.
//

import Combine
import PhotosUI

final class PhotoPreviewViewModel: ObservableObject {
    @Published var isShowingResult = false
    @Published var classificationResult: ClassificationResult?
    @Published var isClassifying = false

    func classify(image: UIImage) {
        isClassifying = true

        Task {
//            let result = await ImageClassifier.shared.classify(image: image)
            let result = ClassificationResult(label:"test", confidence:0) //placeholder for now

            await MainActor.run {
                self.classificationResult = result
                self.isShowingResult = true
                self.isClassifying = false
            }
        }
    }
}

struct ClassificationResult {
    let label: String
    let confidence: Double
}
