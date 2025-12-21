import Foundation
import UIKit

enum AvatarImageProcessor {
  static func makeAvatarJPEG(
    from originalData: Data,
    maxPixel: CGFloat = 320,
    maxBytes: Int = 450 * 1024
  ) -> (jpeg: Data, preview: UIImage)? {
    guard let image = UIImage(data: originalData) else { return nil }
    let normalized = normalizeOrientation(image)
    let squared = cropToSquare(normalized)
    let resized = resize(squared, maxPixel: maxPixel)

    var quality: CGFloat = 0.82
    var data = resized.jpegData(compressionQuality: quality)
    while let d = data, d.count > maxBytes, quality > 0.4 {
      quality -= 0.1
      data = resized.jpegData(compressionQuality: quality)
    }

    guard let jpeg = data else { return nil }
    return (jpeg: jpeg, preview: resized)
  }

  private static func normalizeOrientation(_ image: UIImage) -> UIImage {
    guard image.imageOrientation != .up else { return image }
    let renderer = UIGraphicsImageRenderer(size: image.size)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: image.size))
    }
  }

  private static func cropToSquare(_ image: UIImage) -> UIImage {
    let size = image.size
    let length = min(size.width, size.height)
    let origin = CGPoint(x: (size.width - length) / 2, y: (size.height - length) / 2)
    let rect = CGRect(origin: origin, size: CGSize(width: length, height: length))
    guard let cg = image.cgImage?.cropping(to: rect.applying(CGAffineTransform(scaleX: image.scale, y: image.scale))) else {
      return image
    }
    return UIImage(cgImage: cg, scale: image.scale, orientation: .up)
  }

  private static func resize(_ image: UIImage, maxPixel: CGFloat) -> UIImage {
    let size = image.size
    let maxSide = max(size.width, size.height)
    guard maxSide > maxPixel else { return image }
    let scale = maxPixel / maxSide
    let target = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))
    let renderer = UIGraphicsImageRenderer(size: target)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: target))
    }
  }
}

